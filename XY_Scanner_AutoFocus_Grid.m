%% File: XY_Scanner_AutoFocus_Grid.m
% Author(s): Robby Nelson (rnelson71@gatech.edu)
% System Requirements: r2022b (or newer)
% Created: 3/13/23
% Last Modified: 3/13/23


classdef XY_Scanner_AutoFocus_Grid
    
    properties
        SERVO
        PIEZO
        PCO_CAMERA
        FILTER_WHEEL
        FOCUS_STRATEGY
        BRENNER_AUTO_FOCUS
        SCAN_NOW
        
    end
    
    methods
        function self = XY_Scanner_AutoFocus_Grid(servo, piezo, pco_camera, filter_wheel, focus_strategy, fom_autofocus)
            self.SERVO = servo;
            self.PIEZO = piezo;
            self.PCO_CAMERA = pco_camera;
            self.FILTER_WHEEL = filter_wheel;
            self.FOCUS_STRATEGY = focus_strategy;
            self.BRENNER_AUTO_FOCUS = fom_autofocus;
        end
        
        function [self] = start_scan(self, x_start, y_start, x_step_size, y_step_size, num_square_blocks_x, num_square_blocks_y, square_block_size, wavelengths, file_location, file_name, exposure_times)
            self.SCAN_NOW = 1;
            
            xy_focus_positions = cat(3, zeros(num_square_blocks_x, num_square_blocks_y), zeros(num_square_blocks_x, num_square_blocks_y));
            z_focus_positions = NaN(num_square_blocks_x, num_square_blocks_y)

            %% Create matrix with XY positions for where the focus should be measured for each block

            xy_focus_positions(1, :, 1) = x_start + (floor(square_block_size / 2) .* x_step_size);
            for i = 2:num_square_blocks_x
                 xy_focus_positions(i, :, 1) = xy_focus_positions(i - 1, :, 1) + (square_block_size .* x_step_size);
            end

            xy_focus_positions(:, 1, 2) = y_start + (floor(square_block_size / 2) .* y_step_size);
            for i = 2:num_square_blocks_y
                 xy_focus_positions(:, i, 2) = xy_focus_positions(:, i - 1, 2) + (square_block_size .* y_step_size);
            end

            %% imaging with 255nm and collection of AF data
            self.PCO_CAMERA.set_exposure_time(exposure_times(3));
            
            for i = 1:(num_square_blocks_x * square_block_size)
                
                current_x_pos = x_start + ((i - 1) * x_step_size);
                self.SERVO.set_abs_pos_x(10^3 * current_x_pos);
                current_block_number_x = floor((i - 1) ./ square_block_size) + 1;

                for j = 1:(num_square_blocks_y * square_block_size)
                    
                    if ~self.SCAN_NOW % Make sure that the stop button was not pressed
                        return;
                    end

                    current_y_pos = y_start + ((j - 1) * y_step_size);
                    self.SERVO.set_abs_pos_y(10^3 * current_y_pos);
                    current_block_number_y = floor((j - 1) ./ square_block_size) + 1;

                    %% z focusing
                    curr_focus_z = z_focus_positions(current_block_number_x, current_block_number_y);

                    if isnan(curr_focus_z) % we need to acquire the focus
                        self.SERVO.set_abs_pos_x(10^3 * xy_focus_positions(current_block_number_x, current_block_number_y, 1));
                        self.SERVO.set_abs_pos_y(10^3 * xy_focus_positions(current_block_number_x, current_block_number_y, 2));

                        if strcmp(self.FOCUS_STRATEGY, 'SingleShot')
                            self.PCO_CAMERA.capture_image('C:\imaging', 'single_shot_af', 1);   
                            new_focus = SingleShot(self.PIEZO.get_abs_pos());
                            self.PIEZO.set_abs_pos(new_z);
                        else
                            self.BRENNER_AUTO_FOCUS.focus();
                            new_focus = self.PIEZO.get_abs_pos() + 2;
                            pause(.5);
                            self.PIEZO.set_abs_pos(new_focus);
                        end

                        z_focus_positions(current_block_number_x, current_block_number_y) = new_focus;
                        
                        self.SERVO.set_abs_pos_x(10^3 * current_x_pos);
                        self.SERVO.set_abs_pos_y(10^3 * current_y_pos);

                    else
                        self.PIEZO.set_abs_pos(curr_focus_z);
                    end
                
                    self.PCO_CAMERA.capture_image(file_location, [file_name '_255nm_' num2str(((i - 1) .* num_square_blocks_y .* square_block_size) + j)], 1);   

                end
            end

            %% imaging with all other wavelengths
            dispersion_measurement = [-21.97 -5.5 12.80 20.8 44.49];
            wavelength_name = ["220" "239" "280" "300" "415"];
            wavelengths = [wavelengths(1:2) wavelengths(4:6)];
            exposure_times_modified = [exposure_times(1:2) exposure_times(4:6)];

            for w = 1:length(wavelengths)
                if ~wavelengths(w)
                    continue;
                end
                
                curr_exp_time = exposure_times_modified(w);
                self.PCO_CAMERA.set_exposure_time(curr_exp_time);
                self.FILTER_WHEEL.set_wavelength(str2num(wavelength_name(w)));
                pause(3.5); % wait for the filter wheel to finish turning 

                current_z_focus_pos = z_focus_positions + dispersion_measurement(w);

                for i = 1:(num_square_blocks_x * square_block_size)
                
                    current_x_pos = x_start + ((i - 1) * x_step_size);
                    self.SERVO.set_abs_pos_x(10^3 * current_x_pos);
                    current_block_number_x = floor((i - 1) ./ square_block_size) + 1;
    
                    for j = 1:(num_square_blocks_y * square_block_size)
                        
                        if ~self.SCAN_NOW % Make sure that the stop button was not pressed
                            return;
                        end
    
                        current_y_pos = y_start + ((j - 1) * y_step_size);
                        self.SERVO.set_abs_pos_y(10^3 * current_y_pos);
                        current_block_number_y = floor((j - 1) ./ square_block_size) + 1;
    
                        %% z focusing
                        curr_focus_z = current_z_focus_pos(current_block_number_x, current_block_number_y);
                      
                        self.PIEZO.set_abs_pos(curr_focus_z);

                        self.PCO_CAMERA.capture_image(file_location, [file_name '_' char(wavelength_name(w)) 'nm_' num2str(((i - 1) .* num_square_blocks_y .* square_block_size) + j)], 1);   
                    end
    
                end
            


            end



            self.SCAN_NOW = 0;
        end

        function [self] = stop(self)
            self.SCAN_NOW = 0;
        end
                       
        
    end
end

