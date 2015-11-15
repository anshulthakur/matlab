function p = p_blocking( num_servers, mu, lambda )
%P_BLOCKING Calculates the blocking probability Erlang C
    rho = lambda/(mu * num_servers);
    numerator = (((num_servers*rho)^num_servers)/factorial(num_servers))*(1/(1-rho));
    denominator = 0;
    for k=0:(num_servers -1)
        denominator = denominator + (((num_servers * rho)^k)/factorial(k));
    end
    denominator = denominator +numerator;
    p= double(numerator/denominator);

end
