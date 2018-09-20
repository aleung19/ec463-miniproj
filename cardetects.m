function detectedcars = cardetects(videofile, framerate)
v = vision.VideoFileReader(videofile); % read footage
detector = vision.ForegroundDetector('NumGaussians', 5, ...
    'NumTrainingFrames', 70); % creates foreground mask
blob = vision.BlobAnalysis('AreaOutputPort', false, ...
     'BoundingBoxOutputPort', true, 'CentroidOutputPort', false, ...
     'MinimumBlobArea', 3500); % analyzes connected regions in the mask 
carcandidates = struct('id',{},'bboxes',{},'framesgone',{},'timestamp', ... 
    {}, 'cargone',{});
activetracks = carcandidates;
carsfinal = {};
% each entry in this structure holds detections that are candidates to be
% legitimate car tracking
se = strel('square', 3);
numcars = 0;
videoPlayer = vision.VideoPlayer();
newtracks = [];
framecounter = 0;
[carcandidates, activetracks] = processvid(v, detector, blob, ...
    carcandidates, activetracks, se, numcars, videoPlayer, newtracks, ...
    framecounter, framerate);
carsfinal = finalizecars(carsfinal, numcars, activetracks, carcandidates);
detectedcars = cell2mat(carsfinal);
csvwrite('carsandtimestamps.txt', detectedcars);
type('carsandtimestamps.txt')
% We'll only consider a track a legitimate car candidate if it
% appears over a certain number of frames
end
