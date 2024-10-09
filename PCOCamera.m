%% File: PCO_Camera.m
% Author(s): Robby Nelson (rnelson71@gatech.edu)
% System Requirements: r2019b (or newer)
% Created: 9/26/2022
% Last Modified: 9/26/2022

%% Functions:

% constructor
% input: none
% outputs: none

% set_exposure_time
% input: exposure time
% outputs: none

% get_vid
% input: none
% outputs: video object 

% capture_image
% input: save file path, file name
% outputs: none

% close_camera
% input: none
% outputs: none

%% Code

classdef PCOCamera < handle
    
    properties
        
        VID
        SRC
        
    end
    
    methods
        
        function self = PCOCamera()
            
            if verLessThan('matlab','8.2')%R2013a or older
                error('This adaptor is supported in Matlab 2013b and later versions'); 
            elseif verLessThan('matlab','9.0') %R2015b - R2013b
                if(strcmp(computer('arch'),'win32'))
                    adaptorName = ['pcocameraadaptor_r' version('-release') '_win32'];
                elseif(strcmp(computer('arch'),'win64'))
                    adaptorName = ['pcocameraadaptor_r' version('-release') '_x64'];
                else
                    error('This platform is not supported.');
                end
            else %R2016a and newer
                if(strcmp(computer('arch'),'win64'))
                    adaptorName = ['pcocameraadaptor_r' version('-release')];
                else
                    error('This platform is not supported.');
                end
            end
            
            %Create video input object
            self.VID = videoinput(adaptorName, 0);
            self.VID.LoggingMode = 'memory';
            self.VID.PreviewFullBitDepth = 'on';
            triggerconfig(self.VID, 'immediate');
            self.VID.FramesPerTrigger = 1;
            set(self.VID, 'Timeout', 8); 
            
            self.SRC = getselectedsource(self.VID);
            self.SRC.E1ExposureTime_unit = 'us';
            
        end
        
        function [] = set_exposure_time(self, exp_time)
            
            self.SRC.E2ExposureTime = exp_time;
            
        end
        
        function [vid] = get_vid(self)
            
            vid = self.VID;
            
        end
            
        function [images] = capture_image(self, file_path, file_name, save_file)
            
            start(self.VID);

            try
                images = getdata(self.VID);
            catch ME
                owfehoihiefwoiwef = 3498438934890
            end
            
            if save_file
                save([file_path '\' file_name '.mat'], 'images');
            end
            
        end
        
        function [] = close_camera(self)
           
            imaqreset;
            
        end
        
    end

    
end

