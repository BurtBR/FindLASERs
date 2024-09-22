clc; clear; close all;

InputFolder = "Images";
OutputFolder = "Saturation230";
RadiustoSearch = [2 20];
SaturationThreshold = 230;
SquareThreshold = 2; % Aspect ratio of LASERs

FilterKernel = [-1 -1 -1;
                -1  8 -1;
                -1 -1 -1]; % Edge Detector Filter

if ~CheckFolders(InputFolder, OutputFolder)
    return;
end

imagefiles = dir(InputFolder);
imagelimit = length(imagefiles);

set(groot, "defaultFigureWindowState", "maximized");

for counter = 3:imagelimit
    close all;
    currimage = imread(imagefiles(counter).folder+"\"+imagefiles(counter).name);

    grayimage = rgb2gray(currimage);

    binaryimage = BinarizeImage(grayimage,SaturationThreshold);
    filteredimage = filter2(FilterKernel, binaryimage, "valid");
    
    fig = figure('WindowState', 'maximized');imshow(binaryimage);title("Saturation");
    img = getframe(fig);
    imwrite(img.cdata, OutputFolder+"\Saturation_"+imagefiles(counter).name);

    figure('WindowState', 'maximized'); imshow(filteredimage);title("Filtered");

    [imageresult, anchorqty] = FindBySaturationGroup(currimage, FilterKernel, SaturationThreshold, RadiustoSearch, SquareThreshold);
    fig = figure('WindowState', 'maximized');imshow(imageresult);title("Group by saturation: " + anchorqty + " anchors");
    img = getframe(fig);
    imwrite(img.cdata, OutputFolder+"\GroupBySaturation_"+imagefiles(counter).name);

    [centers, radii, metric] = imfindcircles(binaryimage,RadiustoSearch);
    fig = figure('WindowState', 'maximized');imshow(currimage);title("ImFindCircles: "+ size(centers,1) + " anchors");
    viscircles(centers, radii,'EdgeColor','r');
    img = getframe(fig);
    imwrite(img.cdata, OutputFolder+"\ImFindCircles_"+imagefiles(counter).name);
    
    %return;
end

function result = BinarizeImage(image, threshold)
    result = zeros(size(image));
    for y = 1:size(image,1)
        for x = 1:size(image,2)
            if(image(y,x) > threshold)
                result(y,x) = 1;
            end
        end
    end
end

function [result, anchorqty] = FindBySaturationGroup(image, filterkernel, threshold, radius, aspectthreshold)

    grayimage = rgb2gray(image);
    filteredimage = filter2(filterkernel, BinarizeImage(grayimage,threshold), "valid");
    result = repmat(grayimage,[1,1,3]);

    colortopaint = [255 0 0];
    anchorqty = 0;

    for y = 1:size(filteredimage,1)
        for x = 1:size(filteredimage,2)
            if(filteredimage(y,x) > 0)
                [filteredimage, x1, y1, x2, y2] = RecursiveGroup(filteredimage, 0, x, y, x, y, x, y);

                aspect = (x2-x1)/(y2-y1);

                if( (x2-x1) > radius(1) && (x2-x1) < radius(2) && ...
                    (y2-y1) > radius(1) && (y2-y1) < radius(2) && ...
                    aspect > 1/aspectthreshold && aspect < aspectthreshold)
                    
                    result(y1:y2,x1:x2,1) = colortopaint(1);
                    result(y1:y2,x1:x2,2) = colortopaint(2);
                    result(y1:y2,x1:x2,3) = colortopaint(3);
    
                    result = insertText(result, [x1 y1], "V",TextColor="red", BoxOpacity=0, AnchorPoint="LeftBottom");
    
                    anchorqty = anchorqty+1;
                end
            else
                filteredimage(y,x) = 0;
            end
        end
    end
end

function [image, x1,y1,x2,y2] = RecursiveGroup(curimage, threshold, curx, cury, curx1, cury1, curx2, cury2)

    x1 = curx1;
    y1 = cury1;
    x2 = curx2;
    y2 = cury2;
    image = curimage;

    if(curx < 1 || curx > size(curimage,2) || cury < 1 || cury > size(curimage,1))
        return;
    end

    if(image(cury,curx) > threshold)
        image(cury,curx) = 0;
        if(curx < x1)
            x1 = curx;
        elseif(curx > x2)
            x2 = curx;
        end
        if(cury < y1)
            y1 = cury;
        elseif(cury > y2)
            y2 = cury;
        end
        [image, x1, y1, x2, y2] = RecursiveGroup(image,threshold,curx-1,cury-1,x1,y1,x2,y2);
        [image, x1, y1, x2, y2] = RecursiveGroup(image,threshold,curx,cury-1,x1,y1,x2,y2);
        [image, x1, y1, x2, y2] = RecursiveGroup(image,threshold,curx+1,cury-1,x1,y1,x2,y2);
        [image, x1, y1, x2, y2] = RecursiveGroup(image,threshold,curx-1,cury,x1,y1,x2,y2);
        [image, x1, y1, x2, y2] = RecursiveGroup(image,threshold,curx+1,cury,x1,y1,x2,y2);
        [image, x1, y1, x2, y2] = RecursiveGroup(image,threshold,curx-1,cury+1,x1,y1,x2,y2);
        [image, x1, y1, x2, y2] = RecursiveGroup(image,threshold,curx,cury+1,x1,y1,x2,y2);
        [image, x1, y1, x2, y2] = RecursiveGroup(image,threshold,curx+1,cury+1,x1,y1,x2,y2);
    else
        image(cury,curx) = 0;
        return;
    end
end

function condition = CheckFolders(in, out)
    if ~exist(in, 'dir')
        disp("Input folder does not exists!");
        condition = false;
        return;
    end
    
    if ~exist(out, 'dir')
        mkdir(out);
        if ~exist(out, 'dir')
            disp("Fail to create output folder!");
            condition = false;
            return;
        end
    end

    condition = true;
end