function [f_h, center_logi_in, left_logi_in, upleft_logi_in] = ...
    plot_MBSFN_SINR_3areas(center_bool, left_bool, upleft_bool, ...
    SINR, x_lim, y_lim, mk_size, f_h, POI, varargin)
%blue = [0 0.4470 0.7410];
yellow = [0.9290, 0.6940, 0.1250];
brown = [0.75, 0.75, 0];
black = [0.25, 0.25, 0.25];

temp_data_folder = "MBSFN_Area_7site";

loaded_center = load(fullfile(temp_data_folder, ...
    temp_data_folder + "_center_outlier_clear.mat"), ...
    'UE_attached_eNodeB', 'UE_pos', 'UE_TB_SINR_dB');
loaded_left = load(fullfile(temp_data_folder, ...
    temp_data_folder + "_left_outlier_clear.mat"), ...
    'UE_attached_eNodeB', 'UE_pos', 'UE_TB_SINR_dB');
loaded_upleft = load(fullfile(temp_data_folder, ...
    temp_data_folder + "_upleft_outlier_clear.mat"), ...
    'UE_attached_eNodeB', 'UE_pos', 'UE_TB_SINR_dB');

center_cell_list = sort(unique(loaded_center.UE_attached_eNodeB));
left_cell_list = sort(unique(loaded_left.UE_attached_eNodeB));
upleft_cell_list = sort(unique(loaded_upleft.UE_attached_eNodeB));

% var: sector_pos_improved, site_pos
load('TS36942_urban_ISD500_res10_4ring_sector_area.mat', ...
    'sector_pos_improved', 'site_pos');
plot_pos = round(site_pos);
outer_site = [1:5, 9:11, 19, 20, 28, 29, 37, 38, 46:48, 54:57, 59:61];
outer_cell = [outer_site*3-2, outer_site*3-1, outer_site*3];
figure(f_h)
xlim(x_lim)
ylim(y_lim)
hold on
% environmental cells
for cell_ID = 1 : size(site_pos, 2) * 3
    if ismember(cell_ID, outer_cell) || ...
            ismember(cell_ID, center_cell_list) || ...
            ismember(cell_ID, left_cell_list) || ...
            ismember(cell_ID, upleft_cell_list)
        continue
    end
    UE_area = sector_pos_improved{cell_ID};
    X_arr = UE_area(:, 1);
    Y_arr = UE_area(:, 2);
    h = scatter(X_arr, Y_arr, mk_size, yellow, 'square', 'filled');
    c = mod(cell_ID, 3) + 1;
    h.MarkerFaceAlpha = c * 0.3 + 0.1;
    t= text(prctile(X_arr, 35), prctile(Y_arr, 45), ...
        num2str(cell_ID), 'FontSize', 10);
    set(t, 'Color', [0.8100, 0.3100, 0.1700]) % deep orange
    set(t, 'FontWeight', 'Bold');
end

% plot site
scatter(plot_pos(1, :), plot_pos(2, :), 40, 'k', '<', 'filled');
scatter(plot_pos(1, :), plot_pos(2, :), 20, 'r', 'o', 'filled');

% selected areas
center_sinr_avg = mean(loaded_center.UE_TB_SINR_dB(2:end, :), 1);
center_sinr_f = (center_sinr_avg >= SINR);
center_UE_pos(1, :) = loaded_center.UE_pos(1, center_sinr_f);
center_UE_pos(2, :) = loaded_center.UE_pos(2, center_sinr_f);
if center_bool
    scatter(center_UE_pos(1, :), center_UE_pos(2, :), ...
        mk_size, brown, 'square', 'filled');
end
% left
left_sinr_avg = mean(loaded_left.UE_TB_SINR_dB(2:end, :), 1);
left_sinr_f = (left_sinr_avg >= SINR);
left_UE_pos(1, :) = loaded_left.UE_pos(1, left_sinr_f);
left_UE_pos(2, :) = loaded_left.UE_pos(2, left_sinr_f);
if left_bool
    scatter(left_UE_pos(1, :), left_UE_pos(2, :), ...
        mk_size, brown, 'square', 'filled');
end
% upleft
upleft_sinr_avg = mean(loaded_upleft.UE_TB_SINR_dB(2:end, :), 1);
upleft_sinr_f = (upleft_sinr_avg >= SINR);
upleft_UE_pos(1, :) = loaded_upleft.UE_pos(1, upleft_sinr_f);
upleft_UE_pos(2, :) = loaded_upleft.UE_pos(2, upleft_sinr_f);
if upleft_bool
    scatter(upleft_UE_pos(1, :), upleft_UE_pos(2, :), ...
        mk_size, brown, 'square', 'filled');
end

% draw polygon (POI)
if size(POI, 2) < 3
    error("At least 3 points to form a polygon.")
end

% get coordinates of POI
[intersect_y, x_lim] = convex_polygon_fill(POI);
plot_ratio = 10;           % pre-checked
% pre-checked, should be less than ratio, round to 4 decimals
plot_origin = [0, 5.8984]; 
% get list of coordinates with plot ratio and origins
area_size = sum(intersect_y(2, :) - intersect_y(1, :));
% upper bound for pre-allocate list length
approximate_coord_size = 2 * area_size / (plot_ratio^2);
POI_coor = nan(2, approximate_coord_size);
cnt = 0;
x_start = plot_ratio * floor(x_lim(1)/plot_ratio) + plot_origin(1);
for i = x_start : plot_ratio : x_lim(2)
    x_idx = i - x_lim(1) + 1;
    y_start = plot_ratio * floor(intersect_y(1, x_idx)/plot_ratio) + plot_origin(2);
    for j = y_start : plot_ratio : intersect_y(2, x_idx)
        cnt = cnt + 1;
        POI_coor(1, cnt) = i;
        POI_coor(2, cnt) = j;
    end
end
POI_coor = reshape(POI_coor(~isnan(POI_coor)), 2, []);
if ~isempty(varargin)
    overshooting_exlude = varargin{1};
    if overshooting_exlude
        center_all = check_point_inside(POI_coor, loaded_center.UE_pos);
        left_all = check_point_inside(POI_coor, loaded_left.UE_pos);
        upleft_all = check_point_inside(POI_coor, loaded_upleft.UE_pos);
        POI_coor = POI_coor(:, center_all | left_all | upleft_all);
    end
end

center_logi_in = check_point_inside(POI_coor, center_UE_pos);
left_logi_in = check_point_inside(POI_coor, left_UE_pos);
upleft_logi_in = check_point_inside(POI_coor, upleft_UE_pos);

final_logi_in = zeros(1, length(center_logi_in));
if center_bool
    final_logi_in = final_logi_in | center_logi_in;
end
if left_bool
    final_logi_in = final_logi_in | left_logi_in;
end
if upleft_bool
    final_logi_in = final_logi_in | upleft_logi_in;
end

perc = sum(final_logi_in) / length(final_logi_in);
text(1100, -1700, perc*100 + "% in service");
text(1100, -1800, "of the selected area.")
s1 = scatter(POI_coor(1, final_logi_in), POI_coor(2, final_logi_in), ...
    mk_size, brown, 'square', 'filled');
s2 = scatter(POI_coor(1, ~final_logi_in), POI_coor(2, ~final_logi_in), ...
    mk_size, black, 'square', 'filled');
plot_POI(POI, f_h);
legend([s1, s2], "In Service", "Out of Service")

xlabel('X position (m)', 'FontSize', 10)
ylabel('Y position (m)', 'FontSize', 10)
hold off
end

function logical_list_point_inside = check_point_inside(POI_coor, pos_list)
% mostly, pos_list is much larger than POI_coor, so reduce size first.
POI_min = min(POI_coor, [], 2);
POI_max = max(POI_coor, [], 2);
% enlarge limit for decimal round related comparison problem
min_f = (pos_list >= POI_min-1);
max_f = (pos_list <= POI_max+1);
POI_f = (min_f(1,:) & min_f(2,:) & max_f(1,:) & max_f(2,:));
pos_list = pos_list(:, POI_f);
% Must round to same smaller decimals to use 'equal'
pos_list = round(pos_list, 2);
POI_coor = round(POI_coor, 2);
logical_list_point_inside = nan(1, size(POI_coor, 2));
for i = 1 : size(POI_coor, 2)
%     x_found = (pos_l(1, :) == POI_c(1, i));
%     y_found = (pos_l(2, x_found) == POI_c(2, i));
%     logical_list_point_inside(i) = any(y_found);
    
    logical_list_point_inside(i) = ismember(POI_coor(:, i)', pos_list', 'rows');
end
end

function f_h = plot_POI(POI, f_h)
figure(f_h)
for p = 1 : size(POI, 2)-1
    plot([POI(1, p), POI(1, p+1)], [POI(2, p), POI(2, p+1)], ...
        'r', 'LineWidth', 1.5);
end
plot([POI(1, end), POI(1, 1)], [POI(2, end), POI(2, 1)], ...
    'r', 'LineWidth', 1.5);
end