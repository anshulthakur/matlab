function distribution = poisson_arrival( lambda, time )
%POISSON_ARRIVAL Generates an array of exponential inter-arrival times
distribution = [];

method = 2;
%% Method 1
if method == 1
    arrival_time = random('Exponential',1/lambda);
else
%% Method 2
    arrival_time = -(1/lambda) * log(rand(1));
end

while (arrival_time < time)
    distribution = [distribution arrival_time];
%% Method 1    
if method == 1
    arrival_time = arrival_time + random('Exponential',1/lambda);
%% Method 2
else
    arrival_time = arrival_time + ((-1/lambda)*log(rand(1)));
end
end

end

