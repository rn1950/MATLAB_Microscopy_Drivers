%% File: ExcelScanner.m
% Author(s): Robby Nelson (rnelson71@gatech.edu)
% System Requirements: r2019b (or newer)
% Created: 10/21/2022
% Last Modified: 10/21/2022


classdef ExcelScanner

    properties (Constant)
        
    end
    
    properties
        SERVO
        PIEZO
        PCO_CAMERA
        FILTER_WHEEL
        BRENNER_AUTO_FOCUS
        USE_SINGLE_SHOT
    end
    
    methods
        function self = ExcelScanner(servo, piezo, pco_camera, filter_wheel, brenner_auto_focus, use_single_shot)
            self.SERVO = servo;
            self.PIEZO = piezo;
            self.PCO_CAMERA = pco_camera;
            self.FILTER_WHEEL = filter_wheel;
            self.BRENNER_AUTO_FOCUS = brenner_auto_focus;
            self.USE_SINGLE_SHOT = use_single_shot;
        end
        
        function [] = start_scan(self, x_start, y_start)
            %% XY Scanner
            [~, ~, configuration] = xlsread('XY_scanning.xlsx', 'Configuration');
            [~, ~, wavelengths] = xlsread('XY_scanning.xlsx', 'Wavelengths');
            [~, ~, filenames] = xlsread('XY_scanning.xlsx', 'FileNames');
            
            % Find file names
            file_name_counter = containers.Map;

            % Find wavelengths used
            imaging_wavelengths = [];
            dispersion_property = [-22.2300 -10.6400 0 12.1000 19.5000 43.8700];

            for i = 1:6
                wavelength = wavelengths{1, i};
                if wavelengths{2, i} && (wavelength ~= 255)
                   imaging_wavelengths = [imaging_wavelengths [wavelength; dispersion_property(i); wavelengths{3, i}]]; 
                end
            end

            imaging_wavelengths = [[255; 0; 40000] imaging_wavelengths];

            % Find imaging positions
            size_configuration = size(configuration);
            x_pos = cell2mat(configuration(2:end, 1)');
            y_pos = cell2mat(configuration(1, 2:end));
            x_pos = x_pos + x_start;
            y_pos = y_pos + y_start;
            focus_index = cell2mat(configuration(2:end, 2:end));
            focus_positions = [];
            
            for i = 1:(size_configuration(1) - 1)
                for j = 1:(size_configuration(2) - 1)
                    curr = focus_index(i, j);
                    if (~mod(curr, 100) && (curr > 901))
                        index = curr / 1000;
                        focus_positions(:, index) = [x_pos(i); y_pos(j)];
                    end
                end
            end

            size_focus_positions = size(focus_positions);
            focus_index(~mod(focus_index, 100)) = focus_index(~mod(focus_index, 100)) ./ 1000;
            focus_index(73:81, 64:72) = 100;
            focus_positions = [focus_positions; NaN(1, size_focus_positions(2))];

            size_focus_index = [15 5]; %size(focus_index);
            size_imaging_wavelengths = size(imaging_wavelengths);

            for l = 1:size_imaging_wavelengths(2)
                
                self.FILTER_WHEEL.set_wavelength(imaging_wavelengths(1, l));
                self.PCO_CAMERA.set_exposure_time(imaging_wavelengths(3, l));
                pause(3);

                for i = 1:size_focus_index(1)
                    x_pos_curr = x_pos(i);
                    self.SERVO.set_abs_pos_x(10^3 * x_pos_curr);
                    disp([num2str(i) 'out of' num2str(size_focus_index(1))]);
                    
                    if (i ~= 1) && (i ~= 73) && (mod(i, 9) == 1)
                        curr_focus = focus_index(i-1, 1);
                        self.PIEZO.set_abs_pos(focus_positions(3, curr_focus) + imaging_wavelengths(2, l));
                    end
                    
                    for j = 1:size_focus_index(2)

                        try
                            y_pos_curr = y_pos(j);
                        catch ME
                            fiujewofjef = 98598985;
                        end

                        self.SERVO.set_abs_pos_y(10^3 * y_pos_curr);
                        
                        
                        curr_focus = focus_index(i, j)
                        if isnan(focus_positions(3, curr_focus))
                            x_pos_focus = focus_positions(1, curr_focus);
                            y_pos_focus = focus_positions(2, curr_focus);
                            self.SERVO.set_abs_pos_x(10^3 * x_pos_focus);
                            pause(.3);
                            self.SERVO.set_abs_pos_y(10^3 * y_pos_focus);
                            pause(.3);
                            
                            if (self.USE_SINGLE_SHOT)
                                self.PCO_CAMERA.capture_image('C:\imaging', 'single_shot_af', 1);                    
                                new_z = SingleShot(self.PIEZO.get_abs_pos());
                                self.PIEZO.set_abs_pos(new_z);
                                focus_positions(3, curr_focus) = new_z;
                                
                            else
                                self.BRENNER_AUTO_FOCUS.focus();
                                pause(.2);
                                try
                                    brenner_result = self.PIEZO.get_abs_pos();
                                catch ME
                                    pause(1);
                                    brenner_result = self.PIEZO.get_abs_pos();
                                end

                                focus_positions(3, curr_focus) = brenner_result;
                            end
                         
                            self.SERVO.set_abs_pos_x(10^3 * x_pos_curr);
                            pause(.3);
                            self.SERVO.set_abs_pos_y(10^3 * y_pos_curr);
                            pause(.3);
                        end

                        self.PIEZO.set_abs_pos(focus_positions(3, curr_focus) + imaging_wavelengths(2, l));

                        
                        
                        if isKey(file_name_counter, filenames{i, j})
                            file_name_counter(filenames{i, j}) = file_name_counter(filenames{i, j}) + 1;
                            file_counter = file_name_counter(filenames{i, j});
                        else
                            file_counter = 6481;
                            file_name_counter(filenames{i, j}) = 6481;
                        end
                            
                        self.PCO_CAMERA.capture_image('C:\imaging', [filenames{i, j} '_' num2str(imaging_wavelengths(1, l)) '_' num2str(file_counter)], 1);
                        pause(.1);

                    end   
                end
                file_name_counter = containers.Map;
            end
            
                       
        end
    end
end

