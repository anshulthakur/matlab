function time = exponential_distribution( param )
%EXPONENTIAL_DISTRIBUTION Gives an exponentially distributed time value
    time = -(1/param) * log(rand(1));
end

