using Mimi

@defcomp impacttopdowngdpgrowth begin
    regions = Index()

    economicdamage = Variable(index=[time,regions])

    gdp90 = Parameter(index=[regions])

    population = Parameter(index=[time,regions])
    pop90 = Parameter(index=[regions])

    income = Parameter(index=[time,regions])


    temp90 = Parameter(index=[regions])
    bregtmp = Parameter(index=[regions])#Maybe it's good for plots of the damages
    regtmp = Parameter(index=[time,regions])
    alphagrowth=Parameter(index=[regions])
    betagrowth=Parameter(index=[regions])
    betatwogrowth=Parameter(index=[regions])

    function run_timestep(p, v, d, t)

        if !is_first(t)
            for r in d.regions
                ypc = p.income[t, r] / p.population[t, r] * 1000.0
                ypc90 = p.gdp90[r] / p.pop90[r] * 1000.0

                v.economicdamage[t, r] = (p.alphagrowth[r] + p.betagrowth[r]*(p.regtmp[t,r]-p.temp90[r])+ p.betatwogrowth[r]*(p.temp[t,r]-p.temp90[r])^2)*p.income[t,r]
            end
        end
    end
end
