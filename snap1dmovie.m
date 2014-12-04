function snap1dmovie(snapdata, filename, nfield, m, speed, framerate, framequality, outerxsize, outerzsize)
% This function generates a move from GTC snapshots output
% This function uses VideoWriter Object from Matlab, which is only
% supported since 2010b. Check your Matlab Version before using.
%
% "snapdata" is a matlab structure generated by readallsnap
%
% "filename" is the name of your output video
% For example: filename = "a", then output video will be "a.avi"
%
% "nfield" is the field you want to plot in the movie. The defaults are
% 1:phi         % 2: apara        % 3: fluidne
%
% "m" is the poloidal harmonics you want to analyse. 
% Default: pick m_max from the center of the radius in the last snapshot, 
% and use m = [m_max-2: m_max+2]
%
% "speed" is the speed of your movie.
% For example, speed = 2 will generate one frame from 2 snapshot files
% Default: speed = 1
%
% "framerate" is (I guess) the number of frames in one second of movie.
% Default: framerate = 10
%
% "framequality" is the video quality VideoWriter
% Default: framemrate = 75
%
% "outerxsize" and "outerzsize" is the width and height of the movie
% Default: outerxsize = 1200, outerzsize = 800


%% Initialization:handle optional arguments
if ~exist('snapdata','var') || isempty(snapdata)
    error('Error: snapmovie must contain the argument snapdata');
else
    snap = snapdata;
end

if ~exist('filename','var') || isempty(filename)
    % default filename
    filename = 'GTCsnapmovie.avi';
end

if ~exist('m','var') || isempty(m)
    automatic_pick = 1;
    m = [1,2,3,4];
else
    automatic_pick = 0;
end

if ~exist('speed', 'var') || isempty(speed)
    speed=1;
end

if ~exist('framerate', 'var') || isempty(framerate)
    framerate = 10;
end

if ~exist('nfield','var') || isempty(nfield)
    nfield = 1;
end

if ~exist('framequality', 'var') || isempty(framequality)
    framequality = 75;
end

if ~exist('outerxsize', 'var') || isempty(outerxsize)
    outerxsize = 800;
end

if ~exist('outerzsize', 'var') || isempty(outerzsize)
    outerzsize = 600;
end

nFrame=floor(snap.totalnumber/speed);
%% Analysing m-harmonics on each flux surface of each snapshot

fftdata = zeros(snap.mpsi, length(m), snap.totalnumber);

if automatic_pick>0
% target poloidal harmonics not defined
    tmpdata = reshape(snap.poloidata(snap.totalnumber, :, floor(snap.mpsi/2),nfield),[snap.mtgrid,1]);
    tmpdata = fft(tmpdata);
    [val0, m0] = max(tmpdata);
    if m0> length(tmpdata)/2
        % m0 and length(tmpdata)-m0 are complex conjugate to each other
        m0 = length(tmpdata)-m0;
    end
    m = [m0-2:m0+2];
    fprintf('Target poloidal harmnoics not defined.\n');
    fprintf('Automatic Picking picks m= %s \n', strtrim(sprintf('%d ',m)));
end

for istep = 1:snap.totalnumber
    for iflux =1:snap.mpsi
        tmpdata = reshape(snap.poloidata(istep,:,iflux,nfield),[snap.mtgrid,1]);
        tmpdata = fft(tmpdata);
        for i0 = 1:length(m)
            fftdata(iflux, i0, istep) = abs(tmpdata(m(i0)))/snap.mtgrid*sqrt(2);
        end
        
    end
end


%% Prepare Video Writer
vid = VideoWriter(filename);
vid.FrameRate=framerate;
vid.Quality=framequality;

hFig = figure(1);
set(hFig, 'Outerposition', [0 0 outerxsize outerzsize]);

set(gca,'nextplot','replacechildren');
set(gcf,'Renderer','zbuffer');

open(vid)


%% Start writing frames

legend_names = cell(1,length(m)+1);

for k=1:nFrame
    i0=speed*k;
    set(hFig, 'Outerposition', [0 0 outerxsize outerzsize]);
    
    for i=1:length(m)
        tmpdata = reshape(fftdata(:,i,i0),[snap.mpsi,1]);
        plot(snap.rho, tmpdata, '--');
        if i==1
            hold all
        end
        legend_names{i} = strcat('m=',num2str(m(i)));
    end
    rmsdata = reshape(snap.fieldrms(i0, :, nfield), [snap.mpsi, 1]);
    plot(snap.rho, rmsdata , 'k-', 'linewidth',2);
    legend_names{length(m)+1} = 'total amp.';
    hold off
    
    legend(legend_names);
    
    % insert time label for each frame
    ylim = get(gca, 'YLim');
    xlim = get(gca, 'XLim');
    xpos = xlim(2)*0.2;   ypos = ylim(2)*0.8;
    currenttime=['tstep=',num2str(snap.t(i0))];
    text(xpos, ypos,currenttime);
    
    % write the frame into the video
    frame=getframe(gcf);
    writeVideo(vid,frame);
end

% finalization
close(vid)