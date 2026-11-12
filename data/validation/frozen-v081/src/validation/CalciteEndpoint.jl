"""Narrow pure-water calcite endpoint at regulated CO2 partial pressure; not a discovery/gas-path extension."""
struct CalciteCO2Endpoint
    spec::Dict{String,Any}
    function CalciteCO2Endpoint(spec::AbstractDict)
        d=deepcopy(Dict{String,Any}(spec))
        check_keys(d,["temperature_c","solution_pressure_bar","pco2_bar","water_kg","calcite_g","co2_reservoir_mol","source_id","allow_unvalidated_conditions","initial_recipe"],"calcite endpoint")
        d["initial_recipe"]=="degassed_deionised_water_modelled_as_pure_water" || throw(ArgumentError("endpoint profile accepts only the explicitly declared pure-water approximation"))
        d["allow_unvalidated_conditions"]===true || throw(ArgumentError("experimental endpoint requires explicit unvalidated-condition opt-in"))
        for (key,lo,hi) in (("temperature_c",23.,80.),("pco2_bar",0.01,51.),("solution_pressure_bar",0.01,52.),("water_kg",0.001,100.),("calcite_g",0.001,1000.),("co2_reservoir_mol",0.001,100.))
            finite_real(d[key]) && lo<=d[key]<=hi || throw(ArgumentError("invalid explicit endpoint $key"))
        end
        d["solution_pressure_bar"]>=d["pco2_bar"] || throw(ArgumentError("solution pressure cannot be below CO2 partial pressure"))
        d["source_id"] isa AbstractString && !isempty(strip(d["source_id"])) || throw(ArgumentError("endpoint source required"))
        new(d)
    end
end

function endpoint_input(e::CalciteCO2Endpoint)
    d=e.spec;p=d["pco2_bar"]/1.01325;pressure=d["solution_pressure_bar"]/1.01325
    # Atomic weights are read from the selected database in Basic, not used to fit measured solubility.
    # PHREEQC treats the gas target as log partial pressure and applies its native PR correction.
    """
    SOLUTION 1 pure-water model of degassed deionised experimental solvent
      temp $(d["temperature_c"])
      pressure $pressure
      water $(d["water_kg"])
      pH 7 charge
      units mol/kgw
    SELECTED_OUTPUT 1
      -file selected.tsv
      -reset false
      -high_precision true
      -state true
      -pH true
      -temperature true
      -water true
      -charge_balance true
      -percent_error true
      -saturation_indices Calcite CO2(g)
    USER_PUNCH 1
      -headings n_Ca n_C n_H n_O solid_Calcite reservoir_CO2 gfw_Calcite gfw_Ca volume_L rho_kg_L ca_mol_kgw logf_CO2
      -start
      10 PUNCH TOTMOLE("Ca"), TOTMOLE("C"), TOTMOLE("H"), TOTMOLE("O"), EQUI("Calcite"), EQUI("CO2(g)"), GFW("CaCO3"), GFW("Ca"), SOLN_VOL, RHO, TOT("Ca"), LA("CO2")-LK_PHASE("CO2(g)")
      -end
    SAVE solution 1
    END
    USE solution 1
    # Amount in grams is converted using this database's gram formula weight by a generated include.
    """
end

function calcite_endpoint(e::CalciteCO2Endpoint,c::PHREEQCConfig=PHREEQCConfig();root="results")
    # First actual speciation obtains database formula weights and pure-water atom inventory.
    initial=run_phreeqc(c,endpoint_input(e);root,required=["gfw_Calcite","n_Ca","n_C","n_H","n_O"],sources=[e.spec["source_id"]],metadata=Dict("purpose"=>"pure-water endpoint initialization; pH charge acts only on solute-free model water, never measured ion totals"))
    i=only(initial.rows);gfw=parse(Float64,i["gfw_Calcite"]);stock=e.spec["calcite_g"]/gfw
    input=endpoint_input(e)*"\nEQUILIBRIUM_PHASES 1\n Calcite 0 $stock\n CO2(g) $(log10(e.spec["pco2_bar"]/1.01325)) $(e.spec["co2_reservoir_mol"])\nSAVE solution 1\nSAVE equilibrium_phases 1\nDUMP\n -file state.dmp\n -solution 1\n -equilibrium_phases 1\nEND\n"
    run=run_phreeqc(c,input;root,required=["pH","n_Ca","n_C","n_H","n_O","solid_Calcite","reservoir_CO2","rho_kg_L","volume_L","logf_CO2"],sources=[e.spec["source_id"]],metadata=Dict("boundary"=>"regulated CO2 partial pressure; numerical reservoir must remain nonexhausted","initial_recipe"=>e.spec["initial_recipe"],"endpoint_spec"=>e.spec))
    rows=filter(r->r["state"]=="react",run.rows);length(rows)==1 || error("exactly one endpoint reaction expected")
    row=only(rows);initialrow=only(filter(r->r["state"]=="i_soln",run.rows))
    number(k)=parse(Float64,row[k]);remaining=number("solid_Calcite");reservoir=number("reservoir_CO2");gas_added=e.spec["co2_reservoir_mol"]-reservoir
    balances=Dict{String,Any}()
    for (atom,solid_n,gas_n) in (("Ca",1,0),("C",1,1),("H",0,0),("O",3,2))
        expected=parse(Float64,initialrow["n_$atom"])+solid_n*stock+gas_n*e.spec["co2_reservoir_mol"]
        actual=number("n_$atom")+solid_n*remaining+gas_n*reservoir
        residual=actual-expected;tol=1e-8+1e-10*abs(expected)
        balances[atom]=Dict("expected_mol"=>expected,"actual_mol"=>actual,"residual_mol"=>residual,"tolerance_mol"=>tol,"pass"=>abs(residual)<=tol)
    end
    charge_delta=number("charge")-parse(Float64,initialrow["charge"])
    mass_pass=all(v->v["pass"],values(balances));charge_pass=abs(charge_delta)<=1e-9
    supported=remaining>1e-8 && reservoir>1e-6 && abs(number("si_Calcite"))<=1e-7
    solute_ca=number("n_Ca");water=number("mass_H2O");solution_mass=number("rho_kg_L")*number("volume_L")
    result=Dict{String,Any}("spec"=>e.spec,"archive"=>run.directory,"initialization_archive"=>initial.directory,"selected"=>row,"initial_selected"=>initialrow,"remaining_calcite_mol"=>remaining,"calcite_net_dissolved_mol"=>stock-remaining,"CO2_exchange_mol"=>gas_added,"numerical_reservoir_remaining_mol"=>reservoir,"solubility_g_per_kg_water"=>solute_ca*gfw/water,"solubility_g_per_kg_solution"=>solute_ca*gfw/solution_mass,"total_Ca_mg_per_L"=>solute_ca*number("gfw_Ca")*1000/number("volume_L"),"pH_prediction"=>number("pH"),"gas_fugacity_coefficient"=>10.0^number("logf_CO2")/(e.spec["pco2_bar"]/1.01325),"balances"=>balances,"mass_pass"=>mass_pass,"charge_change_eq"=>charge_delta,"charge_pass"=>charge_pass,"boundary_attained"=>supported,"model_applicability"=>"unverified","validation_scope"=>"endpoint calculation only; experimental errors evaluated separately; no accuracy profile, kinetics or chronology certified","manifest"=>run.manifest)
    mass_pass && charge_pass && supported || throw(CalculationError("endpoint conservation or nonexhausted-buffer/equilibrium boundary check failed",run.directory))
    result
end
