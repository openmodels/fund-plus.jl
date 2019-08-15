using Mimi

@defcomp impacttemperaturestress begin
    regions = Index()
    tempstressdeadcost=Variable(index=[time,regions])

    income = Parameter(index=[time,regions])
    population = Parameter(index=[time,regions])
    gdp90 = Parameter(index=[regions])
    pop90 = Parameter(index=[regions])

    temp90 = Parameter(index=[regions])
    regtmp = Parameter(index=[time,regions])
    bregtmp=Parameter(index=[regions])
    alphamortality = Parameter(index=[regions])
    betaonemortality=Parameter(index=[regions])
    betatwomortality=Parameter(index=[regions])
    cmortality=Parameter(index=[regions])

    function run_timestep(p, v, d, t)
        if !is_first(t)
            for r in d.regions
                ypc = 1000.0 * p.income[t, r] / p.population[t, r]
                ypc90 = 1000.0 * p.gdp90[r] / p.pop90[r]

                 # 0.49 is the increase in global temperature from pre-industrial to 1990
                TemperatureStress =(p.alphamortality[r]+(p.betaonemortality[r] * (p.regtmp[t,r]-0.49*p.bregtmp[r])+ p.betatwomortality[r]*(p.regtmp[t,r]-0.49*p.bregtmp[r])^2)*((ypc/ypc90)^(p.cmortality[r])))
                if TemperatureStress> 50
                    TemperatureStress= 50
                end

                if TemperatureStress< -20
                    TemperatureStress= -20
                end

                v.tempstressdeadcost[t, r] = (TemperatureStress/100)*(p.income[t,r]*1000000000)
                #tempmortaility is output as percent of gdp
                #p.regtmp or regstmp?
                end
        end
    end
end