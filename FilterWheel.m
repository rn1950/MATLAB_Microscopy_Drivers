%% File: FilterWheel.m
% Author(s): Robby Nelson (rnelson71@gatech.edu)
% System Requirements: r2019b (or newer)
% Created: 9/21/2022
% Last Modified: 9/21/2022

%% Functions:

% constructor
% input: none
% outputs: none

% set_wavelength
% input: wavelength (example: 415)
% outputs: none

%% Instructions
% Instantiate the FilterWheel() object. The only function available is
% set_wavelength()

%% Code

classdef FilterWheel < handle

    properties (Constant)
        
        % Constants
        SERIAL_NUMBER = 78; 
  
    end
    
    properties
        
        FILTER_WHEEL
        
    end
    
    methods
        
        function self = FilterWheel()
            
            NET.addAssembly('Y:\robles\NLDS\UV_Laser_System_MATLAB_GUI\lib\USB Filter V1.4\PiUsbSDK\bin\AnyCPU\PiUsbNet.dll');
            self.FILTER_WHEEL = PiUsbNet.Filter(FilterWheel.SERIAL_NUMBER);
            
        end
        
        function [] = set_wavelength(self, wavelength)
            
            switch wavelength
                case 220
                    self.FILTER_WHEEL.MoveTo(2);
                case 239
                    self.FILTER_WHEEL.MoveTo(6);
                case 255
                    self.FILTER_WHEEL.MoveTo(3);
                case 280
                    self.FILTER_WHEEL.MoveTo(4);
                case 300
                    self.FILTER_WHEEL.MoveTo(5);
                case 415
                    self.FILTER_WHEEL.MoveTo(1);
            end
            
        end
        
    end
    
end

