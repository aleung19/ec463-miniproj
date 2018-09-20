function carsfinal = finalizecars(carsfinal, numcars, activetracks, ...
    carcandidates)
for p = 1:numel(activetracks)
    if size(activetracks(p).bboxes,1) > 42
            numcars = numcars + 1;
            carcandidates(end + 1).bboxes = activetracks(p).bboxes;
            carcandidates(end).framesgone = activetracks(p).framesgone;
            carcandidates(end).timestamp = activetracks(p).timestamp;
    end
end
idcounter = 1;
i = 1;
while i <= numel(carcandidates)
    if size(carcandidates(i).bboxes,1) > 42
        carcandidates(i).id = idcounter;
        idcounter = idcounter + 1;
    end
    i = i + 1;
end
for r = 1:numel(carcandidates)
if size(carcandidates(r).bboxes,1) > 42
    carsfinal{r,1} = carcandidates(r).id;
    carsfinal{r,2} = carcandidates(r).timestamp;
    carsfinal{r,3} = carcandidates(r).cargone;
end
end
end
