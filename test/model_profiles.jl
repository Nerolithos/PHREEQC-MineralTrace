@testset "Nonordinal profile scope, evidence independence and database coverage" begin
    registry=load_evidence_registry();profiles=load_model_profiles(;registry)
    db=joinpath(@__DIR__,"../data/validation/v071/databases/phreeqc.dat")
    audit=audit_database(db);@test audit["coverage_pass"]
    @test audit["CO2_EOS_available"]=="peng_robinson"
    @test audit["CO2_critical_parameters"]["P_c"]==72.86
    @test bar_to_atm(1.01325)==1.;@test atm_to_bar(1.)==1.01325
    p=profiles["calcite-co2-water-386"]
    q=Dict{String,Any}("database_sha256"=>p.spec["database_sha256"],"activity_model"=>"ion_association","gas_model"=>"peng_robinson","boundary"=>"fixed_partial_pressure","components"=>["Ca","C","H","O"],"minerals"=>["Calcite"],"temperature_c"=>24.,"pco2_bar"=>10.09,"pressure_bar"=>10.12,"ionic_strength_mol_kgw"=>0.065,"observable"=>"total_Ca_as_CaCO3_endpoint")
    r=evaluate_applicability(p,q;registry,database_audit=audit)
    @test r["profile_match_status"]=="experimentally_challenged"
    @test !r["strict_qualified"]
    @test r["applicable_reference_ids"]==["REFLECT-24C-Ca"]
    for (key,value) in [("boundary","fixed_volume"),("boundary","fixed_total_pressure"),("database_sha256",repeat("0",64)),("components",["Na","Cl"]),("minerals",["Quartz"]),("temperature_c",100.),("pressure_bar",100.),("ionic_strength_mol_kgw",1.),("activity_model","pitzer"),("observable","actual_chronology")]
        alt=deepcopy(q);alt[key]=value
        @test evaluate_applicability(p,alt;registry,database_audit=audit)["profile_match_status"]=="outside_documented_scope"
    end
    between=deepcopy(q);between["pco2_bar"]=15.;between["pressure_bar"]=15.03
    @test evaluate_applicability(p,between;registry,database_audit=audit)["profile_match_status"]=="unknown_evidence" # no continuous validation from point hull
    missing=deepcopy(q);delete!(missing,"ionic_strength_mol_kgw")
    @test evaluate_applicability(p,missing;registry,database_audit=audit)["profile_match_status"]=="unknown_evidence"
    @test evaluate_applicability(p,q;registry)["profile_match_status"]=="unknown_evidence"
    mktempdir() do d
        damaged=joinpath(d,"db.dat");write(damaged,replace(read(db,String),r"(?m)^\s*-T_c 304.2[^\n]*"=>""))
        a=audit_database(damaged);@test a["CO2_EOS_available"]!="peng_robinson"
        # Matching a modified query fingerprint cannot hide required EOS properties.
        qs=deepcopy(q);qs["database_sha256"]=a["database_sha256"];ps=deepcopy(p.spec);ps["database_sha256"]=a["database_sha256"]
        @test "gas critical properties" in evaluate_applicability(ModelProfile(ps),qs;registry,database_audit=a)["unmatched_conditions"]
        absent=audit_database(db;species=["MISSING_SPECIES"],phases=["MISSING_PHASE"])
        @test !absent["coverage_pass"]
        e=deepcopy(registry.entries);e["USGS-ex6-386"]["conclusion"]="experimentally_supported"
        fake=joinpath(d,"evidence.toml")
        # Loader refuses engine evidence granting independent experimental status, before file checks.
        entry=e["USGS-ex6-386"];open(io->TOML.print(io,Dict("schema_version"=>1,"entries"=>[entry])),fake,"w")
        @test_throws ArgumentError load_evidence_registry(fake)
        entry=deepcopy(registry.entries["REFLECT-24C-Ca"]);entry["source_path"]=db;entry["source_sha256"]=repeat("0",64)
        open(io->TOML.print(io,Dict("schema_version"=>1,"entries"=>[entry])),fake,"w")
        @test_throws ArgumentError load_evidence_registry(fake)
    end
    metrics=comparison_statistics([1.,2.],[2.,1.]);@test metrics["mean_signed_error"]==0
    @test metrics["mean_absolute_error"]==metrics["root_mean_square_error"]==1
    @test metrics["maximum_absolute_relative_error"]==1
    @test metrics["pointwise_experimental_uncertainty"]=="UNKNOWN"
    @test_throws ArgumentError comparison_statistics([0.],[1.])
end
