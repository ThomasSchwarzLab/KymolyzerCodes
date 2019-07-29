function overlayPunctaTrajectory()
%% getting input folder %%
d = uigetdir(pwd, 'Select a folder');
if (endsWith(d,'RawPunctaFiles'))
    d=char(regexp(d,'.*(?=.RawPunctaFiles)','match'));
end

%% Getting other inputs %%
prompt = {'AlignmentFudge','font scaling'};
dims = [1 35];
definput = {'0.01','20'};
answer = inputdlg(prompt,'Input', dims,definput);
fudgeFactor=str2double(answer{1}); % asking user to input saturation value
fontFactorScaling=str2double(answer{2});% asking user to input delay time for saving movies



%% Finding and loading kymograph %%
[files] = dir(d);
kymofileNumber=find(~cellfun(@isempty,regexp({files.name},'_kymo.tif$')));
kymofilePath=[files(kymofileNumber).folder,filesep,files(kymofileNumber).name];
kymofileInfo=imfinfo(kymofilePath);
[kymofileImage]=imread(kymofilePath);
kymofileImage=uint8(kymofileImage);
%figure; imshow(kymofileImage);

%% Reading traces %%
kymoTraces=struct();
kymoTracesfilesNumber=find(~cellfun(@isempty,regexp({files.name},'_Puncta_[0-9]*_raw.txt$')));
for traceNumber = 1:length(kymoTracesfilesNumber)
    fileNumber=kymoTracesfilesNumber(traceNumber);
    trace=load([files(fileNumber).folder,filesep,files(fileNumber).name]);
    kymoTraces(traceNumber).trace=trace;
    kymoTraces(traceNumber).xCoordinates= trace(1:end,4)+1;
    kymoTraces(traceNumber).tCoordinates= trace(1:end,1)+1;
    kymoTraces(traceNumber).punctaNumber= str2double(cell2mat(regexp(files(fileNumber).name, '(?<=_Puncta_)[0-9]*(?=_raw.txt$)','match')));
end

%% making trace lines %%
kymoTracesImage=zeros(size(kymofileImage));
for traceNumber = 1:length(kymoTraces)
    xCoordinates=kymoTraces(traceNumber).xCoordinates;
    tCoordinates=kymoTraces(traceNumber).tCoordinates;
    for coordinateNumber = 1: length(xCoordinates)
        kymoTracesImage(tCoordinates(coordinateNumber), xCoordinates(coordinateNumber))=1;
    end
end
kymoTracesImage = imbinarize(kymoTracesImage);
se = strel('disk',3);
kymoTracesImage = imdilate(kymoTracesImage,se);
kymoTracesImage = uint8(kymoTracesImage.*255);

%% Writing puncta number for top image %%
punctaNumberImage1=zeros(floor(size(kymofileImage,1)/fontFactorScaling*2),size(kymofileImage,2));
figurePunctaNumberImage1=figure;
imshow(punctaNumberImage1);
hold on;

% deleting the borders on the figure %%
set(gca,'units','pixels'); % set the axes units to pixels
x = get(gca,'position'); % get the position of the axes
set(gcf,'units','pixels'); % set the figure units to pixels
y = get(gcf,'position'); % get the figure position
set(gcf,'position',[y(1) y(2) x(3) x(4)]);% set the position of the figure to the length and width of the axes
set(gca,'units','normalized','position',[0 0 1 1]); % set the axes units to pixels

% writing the numbers %
for traceNumber = 1:length(kymoTraces)
   text= kymoTraces(traceNumber).punctaNumber;
   position=kymoTraces(traceNumber).xCoordinates(1)/size(kymofileImage,2);
   position=position-fudgeFactor;
   annotation(figurePunctaNumberImage1,...
        'textbox',[position 1 0.036467700258398 0.131782945736434],...
        'Color',[1 1 1],...
        'String',{text},...
        'FontSize',floor(size(kymofileImage,1)/fontFactorScaling),...
        'FitBoxToText','on',...
        'LineStyle','none');
end
hold off

% grabbing image as frame %
F = getframe;
close;
punctaNumberImage1=F.cdata(:,:,1);
%% Writing puncta number for bottom image %%
punctaNumberImage2=zeros(floor(size(kymofileImage,1)/fontFactorScaling*2),size(kymofileImage,2));
figurePunctaNumberImage2=figure;
imshow(punctaNumberImage2);
hold on;

% deleting the borders on the figure %%
set(gca,'units','pixels'); % set the axes units to pixels
x = get(gca,'position'); % get the position of the axes
set(gcf,'units','pixels'); % set the figure units to pixels
y = get(gcf,'position'); % get the figure position
set(gcf,'position',[y(1) y(2) x(3) x(4)]);% set the position of the figure to the length and width of the axes
set(gca,'units','normalized','position',[0 0 1 1]); % set the axes units to pixels

% writing the numbers %
for traceNumber = 1:length(kymoTraces)
   text= kymoTraces(traceNumber).punctaNumber;
   position=kymoTraces(traceNumber).xCoordinates(end)/size(kymofileImage,2);
   position=position-fudgeFactor;
   annotation(figurePunctaNumberImage2,'textbox',...
    [position 1 0.036467700258398 0.131782945736434],...
    'Color',[1 1 1],...
    'String',{text},...
    'FontSize',floor(size(kymofileImage,1)/fontFactorScaling),...
    'FitBoxToText','on',...
    'LineStyle','none');
end
hold off

% grabbing image as frame %
F = getframe;
close;
punctaNumberImage2=F.cdata(:,:,1);

%% Making image for gap %%
gapImage=uint8(ones(3,size(kymofileImage,2)).*255);

%% Concatenating Images %%
concatenatedImages1=vertcat(punctaNumberImage1,gapImage,kymoTracesImage,gapImage,punctaNumberImage2);
concatenatedImages2=vertcat(punctaNumberImage1,gapImage,kymofileImage,gapImage,punctaNumberImage2);
multi = cat(3,concatenatedImages1,concatenatedImages2);
montage(multi, 'Size', [size(multi,3) 1], 'BorderSize', [floor(size(multi,1)/30) 0],'BackgroundColor', 'white');
title ('Puncta Number');
