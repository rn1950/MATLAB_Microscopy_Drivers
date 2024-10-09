%% File: BrennerAutoFocus.m
% Author(s): Robby Nelson (rnelson71@gatech.edu)
% System Requirements: r2019b (or newer)
% Created: 10/21/2022
% Last Modified: 10/21/2022

%% Functions:

% constructor
% input: none
% outputs: none


%% Code

classdef BrennerAutoFocus < handle
    
    properties (Constant)
        
        STEP_SIZE = 1;
        
    end
        
    properties
        
        PIEZO
        PCO_CAMERA
        IMAGE_STACK
        Z_CENTER
        STARTING_POS
        
    end
    
    methods
        
        function self = BrennerAutoFocus(piezo, pco_camera)
            
            self.PIEZO = piezo;
            self.PCO_CAMERA = pco_camera;
            
        end
        
        function [error] = focus(self)
            self.IMAGE_STACK = {}; 
            self.Z_CENTER = self.PIEZO.get_abs_pos();
            self.STARTING_POS =  self.Z_CENTER;
            
            starting_pos = self.Z_CENTER - 10;

            for i = 1:.5:21
                current_pos = starting_pos + ((i - 1) .* BrennerAutoFocus.STEP_SIZE);
                self.PIEZO.set_abs_pos(current_pos);
                self.IMAGE_STACK{end + 1} = self.PCO_CAMERA.capture_image('', '', 0);
                pause(.1);
            end
            
            error = self.run_autofocus();
        end
        
        function [error] = run_autofocus(self)
            % try 4 times; if not, give up
            brenner_scores = self.get_brenner(self.IMAGE_STACK);
            curve_fit_min = self.get_curve_fit_min(brenner_scores);
            if (abs(curve_fit_min) < 10)
                self.PIEZO.set_abs_pos(curve_fit_min + self.STARTING_POS -1.5); % goto 1.5 mincron lower than the brenner result
            end
            
            error = 0;
           
        end
        
        function [curve_fit_focus] = get_curve_fit_min(self, brenner_scores)

            x_vals = -10:.5:10;
            curve_fit_focus = 0;
            brenner_smoothed = smooth(brenner_scores);

            
            for i = 2:(length(brenner_scores) - 1)
               
                curr = brenner_smoothed(i);
                if (brenner_smoothed(i-1) > brenner_smoothed(i)) && (brenner_smoothed(i+1) > brenner_smoothed(i))
                    curve_fit_focus = x_vals(i);
                    break;
                end
                
            end

        end

        function [brenner] = get_brenner(self, image)
            brenner = [];
            
%             if iscell(image)
            for i = 1:length(image)
                img = image{i};
                image1 = double(img ./ 1000);
                overall_sum = double(0); % Sum for all i and j (variables are i -> j and j -> k here due to outer for loop) 
                file_size = size(image1);
                for k = 1:(file_size(2) - 10)
                    diff_sum = 0;
                    for j = 1:(file_size(1))
                        diff_sum = diff_sum + (image1(j, k) - image1(j, k + 10))^2; % Brenner gradient calculation
                    end
                    overall_sum = overall_sum + diff_sum; % Add the current row sum to the total
                end
                brenner = [brenner overall_sum];
            end 

            
        end
        
    end

    
end

