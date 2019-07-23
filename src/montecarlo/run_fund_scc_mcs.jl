using Dates

"""
Runs a Monte Carlo simulation with the FUND model over it's distirbutional parameters, and calculates
the Social Cost of Carbon for the specified `years` and discount `rates`.
`trials`: the number of trials to run.
`ntimesteps`: how many timesteps to run.
`output_dir`: an output directory; if none provided, will create and use "output/SCC yyyy-mm-dd HH-MM-SS MCtrials". 
`save_trials`: whether or not to generate and save the MC trial values up front to a file.
"""
function run_fund_scc_mcs(trials = 10000; years = [2020], rates = [0.03], ntimesteps = MimiFUND.default_nsteps + 1, output_dir = nothing, save_trials = false)

    # Set up output directories
    output_dir = output_dir == nothing ? joinpath(@__DIR__, "../../output/", "SCC $(Dates.format(now(), "yyyy-mm-dd HH-MM-SS")) MC$trials") : output_dir
    mkpath("$output_dir/results")

    # Write header in SCC output file
    scc_file = joinpath(output_dir, "scc.csv")
    open(scc_file, "w") do f 
        write(f, "trial, rate, year, scc\n")
    end 

    # Scenario set up
    scenario_args = Any[
        :rate           => rates
        :emissionyear   => years
    ]

    mcs = getmcs()

    # Generate trials
    if save_trials
        filename = joinpath(@__DIR__, "$output_dir/trials.csv")
        generate_trials!(mcs, trials; filename=filename)
    else
        generate_trials!(mcs, trials)
    end

    # Get FUND marginal model
    mm = create_marginal_FUND_model()
    set_models!(mcs, mm)

    # Define scenario function
    function _scenario_func(mcs::Simulation, tup::Tuple)
        
        # Unpack scenario tuple argument
        (rate, emissionyear) = tup
    
        # Get models
        base, marginal = mcs.models
    
        # Perturb emissons in the marginal model
        perturb_marginal_emissions!(marginal, emissionyear)
    
    end

    # Define post trial function
    function scc_calculation(mcs::Simulation, trialnum::Int, ntimesteps::Int, tup::Tuple)

        # Unpack scenario tuple argument
        (rate, emissionyear) = tup
    
        # Get marginal damages
        base, marginal = mcs.models
        marginaldamages = (marginal[:impactaggregation, :loss] - base[:impactaggregation, :loss]) / 10000000.0
    
        # Calculate discount factor
        T = ntimesteps == typemax(Int) ? length(Mimi.dimension(base, :time)) : ntimesteps
        discount_factor = zeros(T)
        idx = getindexfromyear(emissionyear)
        discount_factor[idx:T] = [1 / ((1 + rate) ^ t) for t in 0:T-idx]
    
        # Sum discounted global damages to scc
        scc = sum(sum(marginaldamages, dims = 2)[2:T] .* discount_factor[2:end])
    
        # Write output
        open(scc_file, "a") do f 
            write(f, "$trialnum, $rate, $emissionyear, $scc\n")
        end 
    
        return nothing
    end

    # Run monte carlo trials
    run_sim(mcs;
        models_to_run = 2, 
        ntimesteps = ntimesteps,
        output_dir = "$output_dir/results",
        scenario_args = scenario_args, 
        scenario_func = _scenario_func,   
        post_trial_func = scc_calculation   
        )

    return nothing
end 

