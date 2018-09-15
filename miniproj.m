% function numcars = cardetext(v)
v = vision.VideoFileReader('carfootage-short.mp4'); % read footage
detector = vision.ForegroundDetector('NumGaussians', 5, ...
    'NumTrainingFrames', 70); % creates foreground mask
blob = vision.BlobAnalysis('AreaOutputPort', false, ...
     'BoundingBoxOutputPort', true, 'CentroidOutputPort', false, ...
     'MinimumBlobArea', 3500); % analyzes connected regions in the mask 
carcandidates = struct('bboxes',{},'framespresent',{},'framesgone',{});
% each entry in this structure holds detections that are candidates to be
% legitimate car tracking
se = strel('square', 3);
videoPlayer = vision.VideoPlayer();
while ~isDone(v)
    frame = v();
    foreground = detector(frame);
    foreground1 = bwareaopen(foreground, 500); % noise filter based on size
    foregroundfilt = imopen(foreground1, se); % algorithm noise filter
    BBOX = step(blob, foregroundfilt); % Bounding box coords
    newdetects = BBOX; % We'll consider these bounding boxes new detections
    if isempty(carcandidates) == 1
        for m = 1:size(BBOX,1)
            carcandidates(m).bboxes = BBOX(m,:);
            carcandidates(m).framespresent = 1;
            carcandidates(m).framesgone = 0;
        end
    end % On the first frame of detections, we'll consider all of them
    % candidates -- need to adjust in case first frame has no detections
    activetracks = carcandidates; % Initialize all car candidates as active
    % tracks (tracks that are onscreen)
    nactivetracks = numel(activetracks);
    nnewdetects = size(newdetects,1); 
    for j = 1:nnewddetects
        for k = 1:ncarcandidates
            activetracks = carcandidates;
            if activetracks(k).framesgone > 15
                activetracks(k).framesgone = []; % if a track is gone for
                % over a certain amount of frames, it's removed from the
                % list of active tracks
            end
            if bboxOverlapRatio(newdetects(j,:),carcandidates(k).bboxes(size(carcandidates(k).bboxes,1),:)) > 0.5
                carcandidates(k).bboxes = [carcandidates(k).bboxes; newdetects(j,:)];
                carcandidates(k).framespresent = carcandidates(k).framespresent + 1;
                % new tracks that are candidates for cars are established
                % if bounding boxes over consecutive frames overlap each
                % other over a certain percentage. need to fix so that only
                % active tracks are having their bboxes compared so dead
                % tracks with bboxes that may overlap with new detections
                % don't screw things up
            else
                if carcandidates(k).framespresent > 0
                    carcandidates(k).framesgone = carcandidates(k).framesgone + 1;
                end
                carcandidates(end + 1).bboxes = newdetects(j,:); % problematic looping prob here ...
                % looping through k and adding newdetects(j,:) to
                % carcandidates over and over again?
                carcandidates(end).framespresent = 1;
                carcandidates(end).framesgone = 0;
            end
        end
    end
    shapeInserter = vision.ShapeInserter('BorderColor', 'White');
    out = shapeInserter(frame, BBOX); % adds bounding boxes to video
    videoPlayer(out);
end
    for n = 1:numel(carcandidates)
        if size(carcandidates(n).bboxes,1) < 10
            carcanddiates(n) = [];
        end
    end % eliminating car candidates whose tracks did not last over a
    % certain # of frames
    numcars = numel(carcandidates); % hopefully, # of car candidates is
    % actual # of cars
% Will need to adjust inputs from Raspberry Pi Camera
% Need to perfect a cleaning method, false detections high, cleaning noise
% dependent on size which is not versatile
% Seriously need to debug tracking
