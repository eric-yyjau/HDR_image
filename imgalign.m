function [rimg1,rimg2] = imgalign(img1,img2,iter)

s = size(img1) ~= size(img2);
if s(1)|s(2);
    [h1,w1,c] = size(img1);
    [h2,w2,c] = size(img2);
    if h2 < h1 | w2 < w1;
        'Image2 is smaller than image1'
    end;
    img2 = img2(1:h1,1:w1,:);
end;

imgCell = cell(iter,2);
imgCell{iter,1} = img1;
imgCell{iter,2} = img2;
for i = 1:iter-1;
    imgCell{iter-i,1} = imresize(imgCell{iter-i+1,1},0.5);
    imgCell{iter-i,2} = imresize(imgCell{iter-i+1,2},0.5);
end
% imgCell(1,n) is the smallest, (5,n) is the biggest 
mh = 0;
mw = 0;
% mh : movement in height direction, mw : movement in width direction
% according to the result of smaller img, move the bigger img to a new initial
% place.

for i = 1:iter;
    mw = 2 * mw;
    mh = 2 * mh;
    imgCell{i,2} = imtranslate(imgCell{i,2},[mw,mh]);
    
    gimg1 = rgb2gray(imgCell{i,1});
    gimg2 = rgb2gray(imgCell{i,2});

    thres1 = median(gimg1(:));
    thres2 = median(gimg2(:));
    N = 20;

    bitmap1 = zeros(size(gimg1));
    bitmap2 = zeros(size(gimg2));
    excmap1 = ones(size(gimg1));
    excmap2 = ones(size(gimg2));

    [h,w] = size(gimg1);
    for j = 1:h*w ;
        if gimg1(j) > thres1; bitmap1(j) = 1; end;
        if gimg2(j) > thres2; bitmap2(j) = 1; end;
        if gimg1(j) > thres1 - N && gimg1(j) < thres1 + N; excmap1(j) = 0; end;
        if gimg2(j) > thres2 - N && gimg2(j) < thres2 + N; excmap2(j) = 0; end;
    end;
    % imwrite(bitmap1,['bitmap1_' num2str(i) '.jpg']);
    % imwrite(bitmap2,['bitmap2_' num2str(i) '.jpg']);
    % imwrite(excmap1,['excmap1_' num2str(i) '.jpg']);
    % imwrite(excmap2,['excmap2_' num2str(i) '.jpg']);
    move = zeros(9,1,2);
    move(1,:) = [-1,-1];
    move(2,:) = [0,-1];
    move(3,:) = [1,-1];
    move(4,:) = [-1,0];
    move(5,:) = [0,0];
    move(6,:) = [1,0];
    move(7,:) = [-1,1];
    move(8,:) = [0,1];
    move(9,:) = [1,1];
    value = zeros(9,1);
    % size(bitmap1)
    % size(bitmap2)
    for j = 1:9;
        difference = xor(bitmap1,imtranslate(bitmap2,move(j,:))) & excmap1 & excmap2;
        value(j) = sum(difference(:));
    end
    [minValue,index] = min(value);
    mw = mw + move(index,:,1);
    mh = mh + move(index,:,2);
    imgCell{i,2} = imtranslate(imgCell{i,2},move(index,:));
end
    [rimg1,rimg2] = cutimg(imgCell{iter,1},imgCell{iter,2},[mw,mh]);
end

function [r1,r2] = cutimg(img1,img2,m)
    % height lower bound = hlb
    mw = m(1);
    mh = m(2);
    hlb = 1; wlb = 1;
    hub = size(img1,1);
    wub = size(img1,2);
    if mh > 0;
        hlb = hlb + mh;
    end
    if mh < 0;
        hub = hub + mh;
    end
    if mw > 0;
        wlb = wlb + mw;
    end
    if mw < 0;
        wub = wub + mw;
    end
    r1 = img1(hlb:hub,wlb:wub,:);
    r2 = img2(hlb:hub,wlb:wub,:);
end

