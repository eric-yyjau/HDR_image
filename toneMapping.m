function [mapImg]=toneMapping(img, lightness)
   m = size(img);
   height = m(1);
   width = m(2); 
   imgA = exp(1)+img;
   %min(min(img))
   N = height*width;
   Lw = 0;
   for i = 1:height;
       for j = 1:width;
           Lw = log( imgA(i,j) ) + Lw;
       end
   end
   Lw = Lw/N;
   a = lightness;
   Lm = a*imgA/Lw;
  
   Lwhite = max(max(Lm));
   %
  
   for i = 1:height;
       for j = 1:width;
           Lm(i,j) = Lm(i,j)/(1+Lm(i,j));
       end
   end
   %
   mapImg = Lm;
   
end

