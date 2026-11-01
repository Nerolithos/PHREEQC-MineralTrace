using MineralTrace
try
    println(environment_check(PHREEQCConfig()))
catch e
    showerror(stderr,e)
    println(stderr)
    exit(1)
end
