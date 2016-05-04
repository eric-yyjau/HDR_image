%% Input image
clear
close all
%height = 3456;
%width = 5184;
%input variables
numPics = 7;
file_name = 'pic_';
zmin = 1;
zmax = 256;
imgCell = cell( numPics, 1 );
t = cputime;
B = zeros(numPics,1);
%img = [ width, height, 3, 13];
%count time comsuming
t = cputime;

for i=1:numPics;
 s1 = '/img';
 s2 = [ int2str(i) ];
 if( i < 10 )
     s2 = [ '0' s2 ];
 end
 s3 = '.jpg';
 s = [ file_name s1 s2 s3 ];
 imgCell{i} = imread(s);
 imgCell{i} = imresize(imgCell{i},0.3);
 info = imfinfo(s);
 B(i) = info.DigitalCamera.ExposureTime;
end

%% alignment
iterator = 5;
for time = 1:2;
    for i=2:numPics;
     [ imgCell{1} , imgCell{i} ] = imgalign(imgCell{1}, imgCell{i}, iterator );
    end
end
'finish alignment.'
time_cost = cputime - t
t = cputime;

%% calculate g function
% create the image array X(pixel, images)
imgSize = size(imgCell{1}(:,:,1));
height = imgSize(1);
width = imgSize(2);

numPixels = 50;
for i=1:numPixels;
    x = randi(width);
    y = randi(height);
    for j=1:numPics;
        img = imgCell{j};
        Zr(i,j) = img(y,x,1);
        Zg(i,j) = img(y,x,2);
        Zb(i,j) = img(y,x,3);
    end
end
%Array of shutter speed
B = log(B);
%B(1)=log(13); B(2)=log(10); B(3)=log(4); B(4)=log(3.2); B(5)=log(1);
%B(6)=log(0.8); B(7)=log(0.3); B(8)=log(1/4); B(9)=log(1/60); B(10)=log(1/80);
%B(11)=log(1/320); B(12)=log(1/400); B(13)=log(1/1000);

%[ 13, 10, 4, 3.2, 1, 0.8, 0.3, 1/4, 1/60, 1/80, 1/320, 1/400, 1/1000];

%lamda
l = 1;
%weighting function
w = zeros(1,256);
w(1:128) = (1:128);
w(129:256)=(128:-1:1);
%call functions to solce g, lE
[gr, lEr] = gsolve(Zr,B,l,w);
[gg, lEg] = gsolve(Zg,B,l,w);
[gb, lEb] = gsolve(Zb,B,l,w);

'G function get'
time_cost = cputime - t
t = cputime;

gcell = cell(3,1);
gcell{1} = gr;
gcell{2} = gg;
gcell{3} = gb;

hdrImg = zeros(height,width,3);
for c = 1:3;
    for i = 1:height;
        for j = 1:width;
            wij = 0;
            lEg = 0;
            for k = 2:numPics;
                lE = gcell{c}(imgCell{k}(i,j,c)+1) - B(k);
                lEg = w(imgCell{k}(i,j,c)+1)*lE + lEg;
                wij = wij + w(imgCell{k}(i,j,c)+1); 
            end
            lEg = lEg/wij;
            hdrImg(i,j,c) = exp(lEg);
            hdrImg3(i,j,c) = lEg;
        end
    end
end

%% for histogram picture
hdrImgG = hdrImg3(:,:,2);
imshow(hdrImgG);
colormap jet
caxis auto
%


'finish the hdr image'
time_cost = cputime - t

%% do tone mappping by matlab
maxPix = max(max(max(hdrImg(:,:,:))));
hdrImg2 = hdrImg/maxPix;

rgbImg = tonemap(hdrImg2);
figure;
imshow(rgbImg)
matlab_name = [ file_name '/matlab_rgbImg.bmp' ];
imwrite(rgbImg, matlab_name);



%% other's tonemapping
%fc_tonemap(hdrImg);

% calculate dynamic range
hdrImg3 = hdrImg(:,:,1)*0.299 + hdrImg(:,:,2)*0.587 + hdrImg(:,:,3)*0.114;
maxPix = max(max(hdrImg3));
minPix = min(min(hdrImg3));
%% Tone mapping 

t = cputime;
% Normalization
% trying how to normalize
minP = min(min(hdrImg));
for c=1:3
    %maxPix = max(max(hdrImg(:,:,c)))
    %hdrImg(:,:,c) = hdrImg(:,:,c)/minPix;
    hdrImg(:,:,c) = hdrImg(:,:,c)/min(minP);
end

%%
%throw into tone mapping function

lightness = [ 0.06, 0.08, 0.1, 0.12,0.14]; 
for num = 1 : size(lightness,2);
    mapImg = zeros(height, width, 3);
    for c = 1:3;
        hdrI = hdrImg(:,:,c);
        mapImg(:,:,c) = toneMapping(hdrI,lightness(num));
        %mapImg(:,:,c) = toneMapping2(hdrI);
    end
    max(max(mapImg));
    min(min(mapImg));
    mapImg = round(mapImg*256);
    mapImg = uint8(mapImg);
    figure;
    imshow(mapImg)
    output_name = [ file_name '/' num2str(lightness(num)) '_hdrImg.bmp' ];
    imwrite(mapImg, output_name);
end

'finish tone mapping'
time_cost = cputime - t

%% show non-linear curve
figure
plot(gg);
title('gg');
figure
plot(gr);
title('gr');
figure
plot(gb);
title('gb');


