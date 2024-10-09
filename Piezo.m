%% File: Piezo.m
% Author(s): Robby Nelson (rnelson71@gatech.edu)
% System Requirements: r2019b (or newer)
% Created: 9/12/2022
% Last Modified: 9/20/2022

%% Functions:

% constructor
% input: COM port (example: new_piezo = Piezo('COM1');)
% outputs: none

% set_abs_pos
% input: position in microns (example: set_abs_pos_y(250);)
% outputs: none

% get_abs_pos
% input: none
% outputs: position in microns (ex: 400)

%% Instructions
% Before use, close Kinesis becuase it connects to the COM port and will 
% prevent the MATLAB script from also connecting to the COM port. Verify 
% the correct COM port in Device Manager. At the end of use, run clear 
% before creating a new instance of the Piezo in order to close the prior 
% serial connection.

%% Code

classdef Piezo < handle

    properties (Constant)
        
        % Constants
        Z_STAGE_MAX = 500;
        CONTROLLER_MAX = 32767; 
        
        % Messages
        ABSOLUTE_MOVE_MESSAGE = '46060400D0010100';
        STATUS_UPDATE_MESSAGE = '620600005001';
        IDENTIFY_PIEZO_MESSAGE = '230200005001';
        GET_POSITION_MESSAGE = '470601005001';
        
    end
    
    properties
        
        COM_PORT
        SERIAL_CONNECTION
        
    end
    
    methods
        
        function self = Piezo(com_port)
            
            self.COM_PORT = com_port;

            try
                self.SERIAL_CONNECTION = serialport(self.COM_PORT, 115200);
            catch ME
                error_message = 'COM port used to connect piezo was incorrect or Kinesis was open! Close Kinesis and check the device manager for the correct COM port.';
                error(error_message);
            end
            
            disp(['Instance of piezo class has been constructed on ' self.COM_PORT '.']);
            
        end
        
        function [] = set_abs_pos(self, position)
            
            position_scaled = round(position * (Piezo.CONTROLLER_MAX ./ Piezo.Z_STAGE_MAX));
            position_hex = dec2hex(position_scaled);

            if(length(position_hex) ~= 4)
               pad_zeros_string = repmat('0', 4 - length(position_hex));
               position_hex = [pad_zeros_string position_hex];
            end

            position_hex_flipped = [position_hex(3:4) position_hex(1:2)];   
            movement_command = [Piezo.ABSOLUTE_MOVE_MESSAGE position_hex_flipped];   
            message = sscanf(movement_command, '%2x');   
            write(self.SERIAL_CONNECTION, message, "uint8");
            pause(0.35); % Settling time 
            self.status_update();
            
        end
        
        function [position] = get_abs_pos(self)
            
            flush(self.SERIAL_CONNECTION);
            message = sscanf(Piezo.GET_POSITION_MESSAGE, '%2x'); 
            write(self.SERIAL_CONNECTION, message, "uint8"); 
            com_port_response = read(self.SERIAL_CONNECTION, 10, "uint8");
            com_port_response_hex = dec2hex(com_port_response);      
            position_hex = [com_port_response_hex(10, :) com_port_response_hex(9, :)];
            position_dec = hex2dec(position_hex);
            position = position_dec .* (Piezo.Z_STAGE_MAX ./ Piezo.CONTROLLER_MAX);
            self.status_update();
            
        end
    end
    
    methods(Access = private)
        
        function [] = status_update(self)
            
            message = sscanf(Piezo.STATUS_UPDATE_MESSAGE, '%2x');
            write(self.SERIAL_CONNECTION, message, "uint8");
            
        end
        
    end
    
end

