function x = At_fft3( b, N, mask, P, m, n, o, bComplex )
% 3D IFFT
%
% (c) Thomas Kuestner
% ---------------------------------------------------------------------

if( nargin < 4 ), P = 1:N; end

K = length(b);
fx = complex(zeros(m,n,o),zeros(m,n,o));
fx(mask) = 1/sqrt(2)*b(1:K/2) + 1i *1/sqrt(2)* b(K/2+1:K);
x = zeros(N,1);

if(bComplex)
    fct = sqrt(N/2); % complex input image
else
    fct = sqrt(N); % real input image
end

for i=1:3
    fx = fftshift(ifft(ifftshift(fx,i),[],i),i);
end

if(~bComplex)
    % real input image
    x(P) = abs(fct.*fx(:));
else
    % complex input image
    x(P) = fct.*[1/sqrt(2)*real(fx(:)); 1/sqrt(2)*imag(fx(:))];
end

% x(P) = real(tmp(:)); % phantom

end

