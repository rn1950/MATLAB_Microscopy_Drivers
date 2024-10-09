%% File: Servo.m
% Author(s): Robby Nelson (rnelson71@gatech.edu)
% System Requirements: r2019b (or newer)
% Created: 9/15/2022
% Last Modified: 9/20/2022

%% Functions:

% constructor
% input: COM port (example: new_servo = Servo('COM1');)
% outputs: none

% set_abs_pos_y
% input: position in microns (example: set_abs_pos_y(65000);)
% outputs: none

% set_abs_pos_x
% input: position in microns (example: set_abs_pos_y(65000);)
% outputs: none

% get_abs_pos_x
% input: none
% outputs: position in microns (ex: 40000)

% get_abs_pos_y
% input: none
% outputs: position in microns (ex: 40000)

%% Instructions
% Before use, close Kinesis becuase it connects to the COM port and will 
% prevent the MATLAB script from also connecting to the COM port. Verify 
% the correct COM port in Device Manager. At the end of use, run clear 
% before creating a new instance of the Servo in order to close the prior 
% serial connection.

%% Code

classdef Servo < handle

    properties (Constant)
        
        % Constants
        ENCODER_MICRON_MULTIPLIER = 20;
     
        % Messages
        ABSOLUTE_MOVE_MESSAGE_X = '53040600A1010100';
        ABSOLUTE_MOVE_MESSAGE_Y = '53040600A2010100';
        IDENTIFY_SERVO_MESSAGE = '230201001101';
        REQUEST_ABSOLUTE_X = '110411002101';
        REQUEST_ABSOLUTE_Y = '110411002201';
        
    end
    
    properties
        
        COM_PORT
        SERIAL_CONNECTION
        
    end
    
    methods
        
        function self = Servo(com_port)
            
            self.COM_PORT = com_port;

            try
                self.SERIAL_CONNECTION = serialport(self.COM_PORT, 115200);
            catch ME
                error_message = 'COM port used to connect servo was incorrect or Kinesis was open! Close Kinesis and check the device manager for the correct COM port.';
                error(error_message);
            end
            
            disp(['Instance of servo class has been constructed on ' self.COM_PORT '.']);
            
        end
        
        function [] = set_abs_pos_y(self, position)
            
            if position > 75000
                disp('Requested position is outside 75mm range of Y axis!');
                return;
            end
            
            encoder_pos = position .* Servo.ENCODER_MICRON_MULTIPLIER;
            encoder_pos_hex = dec2hex(ceil(encoder_pos));
            padded_pos_hex = encoder_pos_hex;
            
            if(length(encoder_pos_hex) ~= 8)
               pad_zeros_string = repmat('0', 1, 8 - length(encoder_pos_hex));
               padded_pos_hex = [pad_zeros_string encoder_pos_hex];
            end
            
            swapped_pos_hex = [padded_pos_hex(7:8) padded_pos_hex(5:6) padded_pos_hex(3:4) padded_pos_hex(1:2)];
            full_message = [Servo.ABSOLUTE_MOVE_MESSAGE_Y swapped_pos_hex];
            message = sscanf(full_message, '%2x');
            write(self.SERIAL_CONNECTION, message, "uint8");
            pause(0.3); % Settling time 
            
        end
        
        function [] = set_abs_pos_x(self, position)
            
            if (position > 67000) || (position < 31000)
                disp('Warning! Move not executed: requested position would have hit the objective.');
                return;
            end
            
            encoder_pos = position .* Servo.ENCODER_MICRON_MULTIPLIER;
            encoder_pos_hex = dec2hex(ceil(encoder_pos));
            padded_pos_hex = encoder_pos_hex;
            
            if(length(encoder_pos_hex) ~= 8)
               pad_zeros_string = repmat('0', 1, 8 - length(encoder_pos_hex));
               padded_pos_hex = [pad_zeros_string encoder_pos_hex];
            end
            
            swapped_pos_hex = [padded_pos_hex(7:8) padded_pos_hex(5:6) padded_pos_hex(3:4) padded_pos_hex(1:2)];
            full_message = [Servo.ABSOLUTE_MOVE_MESSAGE_X swapped_pos_hex];
            message = sscanf(full_message, '%2x');
            write(self.SERIAL_CONNECTION, message, "uint8");
            pause(0.3); % Settling time 
            
        end
        
        function [position] = get_abs_pos_x(self)
            
            flush(self.SERIAL_CONNECTION);
            message = sscanf(Servo.REQUEST_ABSOLUTE_X, '%2x');
            write(self.SERIAL_CONNECTION, message, "uint8");
            com_port_response = read(self.SERIAL_CONNECTION, 12, "uint8");
            com_port_response_hex = dec2hex(com_port_response);
            position_hex = [com_port_response_hex(12, :) com_port_response_hex(11, :) com_port_response_hex(10, :) com_port_response_hex(9, :)];
            position_dec = hex2dec(position_hex);
            position = position_dec ./ Servo.ENCODER_MICRON_MULTIPLIER;
            
        end
        
        function [position] = get_abs_pos_y(self)
            
            flush(self.SERIAL_CONNECTION);
            message = sscanf(Servo.REQUEST_ABSOLUTE_Y, '%2x');
            write(self.SERIAL_CONNECTION, message, "uint8");
            com_port_response = read(self.SERIAL_CONNECTION, 12, "uint8");
            com_port_response_hex = dec2hex(com_port_response);
            position_hex = [com_port_response_hex(12, :) com_port_response_hex(11, :) com_port_response_hex(10, :) com_port_response_hex(9, :)];
            position_dec = hex2dec(position_hex);
            position = position_dec ./ Servo.ENCODER_MICRON_MULTIPLIER;
            
        end
        
    end

    
end

