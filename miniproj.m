v = vision.VideoFileReader('carfootage.mp4'); % read footage
detector = vision.ForegroundDetector('NumGaussians', 5, ...
    'NumTrainingFrames', 70); % creates foreground mask
blob = vision.BlobAnalysis('AreaOutputPort', false, ...
     'BoundingBoxOutputPort', true, 'CentroidOutputPort', false, ...
     'MinimumBlobArea', 3500); % analyzes connected regions in the mask 
carcandidates = struct('bboxes',{},'framesgone',{});
activetracks = carcandidates;
% each entry in this structure holds detections that are candidates to be
% legitimate car tracking
se = strel('square', 3);
numcars = 0;
videoPlayer = vision.VideoPlayer();
newtracks = [];
while ~isDone(v)
    frame = v();
    foreground = detector(frame);
    foreground1 = bwareaopen(foreground, 500); % noise filter based on size
    foregroundfilt = imopen(foreground1, se); % algorithm noise filter
    BBOX = step(blob, foregroundfilt); % Bounding box coords
    newdetects = BBOX; % We'll consider these bounding boxes new detections
    if isempty(activetracks) == 1
        for m = 1:size(BBOX,1)
            activetracks(m).bboxes = BBOX(m,:);
            activetracks(m).framesgone = 0;
        end
    end
    % On the first frame of detections, we'll consider all of them
    % candidates for active tracking
    k = 1;
    while k <= numel(activetracks)
        for j = 1:size(newdetects,1)
            overlapRatio = bboxOverlapRatio(newdetects(j,:),activetracks(k).bboxes(end,:));
            if overlapRatio > 0.5
                activetracks(k).bboxes = [activetracks(k).bboxes; newdetects(j,:)];
                % new tracks are established if bounding boxes over 
                % consecutive frames overlap each other over a certain 
                % percentage.
            else
                if size(activetracks(k).bboxes,1) > 0
                    activetracks(k).framesgone = activetracks(k).framesgone + 1;
                end % If no new detections match up to an existing track,
                % a counter goes up for the number of consecutive frames it
                % also doesn't appear
            end
            if activetracks(k).framesgone > 20
                carcandidates(end + 1).bboxes = activetracks(k).bboxes;
                carcandidates(end).framesgone = activetracks(k).framesgone;
                activetracks(k) = [];
            end % If a track has no new detections assigned to it over a
            % certain number of frames, the track is considered no longer
            % on screen and is removed to optimize the loop comparing new
            % detections with existing tracks
        end
        k = k + 1;
    end
    for q = 1:size(newdetects,1)
        activetracks(end + 1).bboxes = newdetects(q,:);
        activetracks(end).framesgone = 0;
    end % If new detections don't match up to existing tracks, they start
    % new tracks
    shapeInserter = vision.ShapeInserter('BorderColor', 'White');
    out = shapeInserter(frame, BBOX); % adds bounding boxes to video
    videoPlayer(out);
end
for p = 1:numel(activetracks)
    carcandidates(end + 1).bboxes = activetracks(p).bboxes;
    carcandidates(end).framesgone = activetracks(p).framesgone;
end % Adding the remaining active tracks to the list of car candidates
    for n = 1:numel(carcandidates)
        if size(carcandidates(n).bboxes,1) > 42
            numcars = numcars + 1;
        end
    end % We'll only consider a track a legitimate car candidate if it
% appears over a certain number of frames
% Will need to adjust for video inputs from Raspberry Pi Camera
% Need to perfect a cleaning method, false detections high, cleaning noise
