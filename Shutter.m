%% File: Shutter.m
% Author(s): Robby Nelson (rnelson71@gatech.edu)
% System Requirements: r2019b (or newer)
% Created: 9/21/2022
% Last Modified: 9/21/2022

%% Functions:

% constructor
% input: none
% outputs: none

% open
% input: none
% outputs: none

% close
% input: none
% outputs: none

%% Instructions
% Instantiate the Shutter() object. Options include Open() or Close().

%% Code

classdef Shutter < handle

    properties (Constant)
        
        % Constants
        SERIAL_NUMBER = 474; 
  
    end
    
    properties
        
        SHUTTER
        
    end
    
    methods
        
        function self = Shutter()
            
            NET.addAssembly('Y:\robles\NLDS\UV_Laser_System_MATLAB_GUI\lib\USB Filter V1.4\PiUsbSDK\bin\AnyCPU\PiUsbNet.dll');
            self.SHUTTER = PiUsbNet.Shutter();
            self.SHUTTER.Open(474);
            
        end
        
        function [] = open(self)
            
            self.SHUTTER.State = PiUsbNet.ShutterState.Open;
            
        end
        
        function [] = close(self)
            
            self.SHUTTER.State = PiUsbNet.ShutterState.Closed;
            
        end
        
    end
    
end

