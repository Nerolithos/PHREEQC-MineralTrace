# Hand-authored numerical fixtures exercise evaluator logic only; never exported as PHREEQC calculations.
@testset "Charge-equivalent arithmetic and evidence schema" begin
    q=charge_equivalents(Dict("Na+"=>0.001,"Cl-"=>0.001),Dict("Na+"=>1,"Cl-"=>-1))
    @test q["percent_error"]==0
    @test q["cation_eq_per_kgw"]==0.001
    @test charge_equivalents(Dict("Ca+2"=>0.001,"F-"=>0.001),Dict("Ca+2"=>2,"F-"=>-1))["percent_error"] ≈ 100/3
    @test charge_equivalents(Dict("CO2"=>0.001),Dict("CO2"=>0))["percent_error"] === nothing
    @test_throws ArgumentError charge_equivalents(Dict("Na"=>true),Dict("Na"=>1))
    @test_throws ArgumentError charge_equivalents(Dict("Na"=>-1.),Dict("Na"=>1))
    @test_throws ArgumentError charge_equivalents(Dict("Na"=>1.),Dict("Cl"=>-1))
    d=Dict{String,Any}("id"=>"T","type"=>"interval","parameter"=>"temperature","units"=>"degC","classification"=>"Observation","lower"=>30.,"upper"=>40.)
    c=EvidenceConstraint(d); @test !haskey(c.spec,"source_id")
    @test !haskey(c.spec,"stage_id")
    for change in (d->(d["units"]="K"),d->(d["lower"]=45.),d->(d["classification"]="Fact"),d->(d["type"]="unknown"))
        bad=deepcopy(d);change(bad);@test_throws ArgumentError EvidenceConstraint(bad)
    end
    outside=deepcopy(d);outside["lower"]=90.;outside["upper"]=100.;@test EvidenceConstraint(outside) isa EvidenceConstraint
    extra=deepcopy(d);extra["value"]=35.;@test_throws ArgumentError EvidenceConstraint(extra)
    base=TOML.parsefile(joinpath(@__DIR__,"../examples/evidence_constraints.toml"))
    @test MineralStudy(base) isa MineralStudy
    bad=deepcopy(base);bad["constraints"][3]["tolerance"]=-1.;@test_throws ArgumentError MineralStudy(bad)
    bad=deepcopy(base);push!(bad["constraints"],bad["constraints"][1]);@test_throws ArgumentError MineralStudy(bad)
end

@testset "Separate quality gates, contribution and missing evidence" begin
    base=TOML.parsefile(joinpath(@__DIR__,"../examples/evidence_constraints.toml"))
    base["constraints"]=Any[]
    function point(t;charge=0.,si=0.,failed=false)
        Dict{String,Any}("coordinates"=>Dict("temperature"=>t,"pH"=>8.),"ix"=>Int((t-25)/5),"iy"=>1,"status"=>failed ? "failed" : abs(si)<0.25 ? "compatible" : "incompatible","selected"=>Dict("pct_err"=>string(charge)),"si"=>Dict("Calcite"=>si,"Fluorite"=>si),"warnings"=>String[],"error"=>failed ? "SYNTHETIC unit-test failure" : "")
    end
    s=MineralStudy(base);p=point(35.)
    e=evaluate_constraints(s,p)
    @test e["computational_status"]=="success"
    @test e["chemical_quality_status"]=="pass"
    @test e["model_applicability_status"]=="unverified"
    @test e["final_status"]=="included_conditional"
    strict=deepcopy(base);strict["evaluation"]["mode"]="strict"
    @test evaluate_constraints(MineralStudy(strict),p)["final_status"]=="unverified"
    @test evaluate_constraints(s,point(35.;charge=1.))["final_status"]=="excluded"
    @test evaluate_constraints(s,point(35.;charge=1.))["regions"]["raw_si"]===true
    @test evaluate_constraints(s,point(35.;failed=true))["regions"]["raw_si"]===nothing
    @test evaluate_constraints(s,point(35.;failed=true);database_phases_available=false)["failure_kind"]=="missing_phase"
    missing=Dict{String,Any}("id"=>"missing","parameter"=>"temperature","type"=>"interval","units"=>"degC","classification"=>"Observation","lower"=>30.,"upper"=>40.)
    strict["constraints"]=[missing]
    em=evaluate_constraints(MineralStudy(strict),p)
    @test em["constraints"][1]["source_status"]=="missing"
    @test em["constraints"][1]["effective_status"]=="unverified"
    stagebase=TOML.parsefile(joinpath(@__DIR__,"../examples/evidence_constraints.toml"))
    sat=only(c for c in stagebase["constraints"] if c["type"]=="saturation")
    delete!(sat,"stage_id");stagebase["constraints"]=[sat]
    @test evaluate_constraints(MineralStudy(stagebase),p)["constraints"][1]["effective_status"]=="unverified"
    exp=deepcopy(base);exp["constraints"]=[missing]
    @test evaluate_constraints(MineralStudy(exp),p)["constraints"][1]["effective_status"]=="pass"
    exp["constraints"][1]["stage_id"]="OTHER-STAGE"
    @test evaluate_constraints(MineralStudy(exp),p)["observation_status"]=="unverified"
    interval(id,lo,hi)=Dict("id"=>id,"type"=>"interval","parameter"=>"temperature","units"=>"degC","classification"=>"Observation","source_id"=>"SYNTHETIC / SIMULATED LOGIC FIXTURE","lower"=>lo,"upper"=>hi)
    base["constraints"]=[interval("A",30.,40.),interval("B",35.,45.),interval("redundant",25.,80.)]
    s=MineralStudy(base);ps=[point(t) for t in (30.,35.,40.,45.)]
    for p in ps;p["evaluation"]=evaluate_constraints(s,p);end
    contribution=constraint_contribution(s,ps)
    @test contribution["baseline_si_and_chemistry_count"]==4
    @test contribution["after_evidence_count"]==2
    @test [x["after"] for x in contribution["sequential"]]==[3,2,2]
    @test [x["added_count"] for x in contribution["leave_one_out"]]==[1,1,0]
    @test contribution["leave_one_out"][3]["redundant_on_grid"]
    @test !contribution["conflict_on_sampled_grid"]
    strictcopy=deepcopy(s.spec);strictcopy["evaluation"]["mode"]="strict";stricts=MineralStudy(strictcopy)
    strictpoints=deepcopy(ps)
    for p in strictpoints;p["evaluation"]=evaluate_constraints(stricts,p);end
    strictcon=constraint_contribution(stricts,strictpoints)
    @test strictcon["baseline_final_inclusion_count"]==0
    @test all(q->q["after"]==0,strictcon["final_sequential"])
    @test all(q->q["added_count"]==0,strictcon["final_leave_one_out"])
    base["constraints"]=[interval("A",30.,30.),interval("B",45.,45.)]
    s=MineralStudy(base)
    for p in ps;p["evaluation"]=evaluate_constraints(s,p);end
    conflict=constraint_contribution(s,ps)
    @test conflict["after_evidence_count"]==0
    @test conflict["conflict_on_sampled_grid"]
    @test all(x->x["conflict_relief"],conflict["leave_one_out"])
    for p in ps;p["status"]="incompatible";p["evaluation"]=evaluate_constraints(s,p);end
    empty=constraint_contribution(s,ps)
    @test !empty["conflict_on_sampled_grid"]
    @test !any(x->x["redundant_on_grid"],empty["leave_one_out"])
    base["constraints"]=Any[];s=MineralStudy(base)
    for (i,p) in enumerate(ps);p["status"]=isodd(i) ? "compatible" : "incompatible";p["evaluation"]=evaluate_constraints(s,p);end
    @test length(MineralTrace.grid_components(ps))==2
end
