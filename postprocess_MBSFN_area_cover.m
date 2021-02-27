clear;clc

parent_dir = fullfile("C:", "Users", "ShenChen", "Documents", "MATLAB", ...
    "Vienna_LTE_system_V15");

% intermediate data extracted
proj_folder = "MBSFN area multiple coverage";
scenario_folder = "MBSFN_Area_7site";
temp_data_folder = fullfile(proj_folder, scenario_folder);

cell_radius = 1200;
all_res_files = dir(fullfile(parent_dir, temp_data_folder, '*.mat'));
for j = 1 : length(all_res_files)
    file_name = all_res_files(j).name;
    if ~contains(file_name, scenario_folder)
       continue 
    end
    if contains(file_name, "_outlier_clear")
        load(fullfile(parent_dir, temp_data_folder, file_name));
    else
        file_n_split = split(file_name, '.');
        newfile_n = file_n_split{1} + "_outlier_clear.mat";
        if any(strcmp({all_res_files.name}, newfile_n))
            continue
        end
        loaded = load(fullfile(parent_dir, temp_data_folder, file_name));
        % convert cell to matrix, make sure second dimension is UE size
        UE_attached_eNodeB = cell2mat(loaded.UE_attached_eNodeB);
        UE_pos = cell2mat(loaded.UE_pos);
        UE_TB_SINR_dB = cell2mat(loaded.UE_TB_SINR_dB')';
        if contains(file_name, "_center")
            origin = [0, 0];
        elseif contains(file_name, "_left")
            origin = [-500, 0];
        elseif contains(file_name, "_upleft")
            origin = [-250, 250*sqrt(3)];
        else
            error("Unknown case.")
        end
        pos_f = ((UE_pos(1,:)-origin(1)).^2 + (UE_pos(2,:)-origin(2)).^2) ...
            <= cell_radius^2;
        UE_attached_eNodeB = UE_attached_eNodeB(1, pos_f);
        UE_pos = UE_pos(:, pos_f);
        UE_TB_SINR_dB = UE_TB_SINR_dB(:, pos_f);
        save(fullfile(parent_dir, temp_data_folder, newfile_n), ...
            'UE_attached_eNodeB', 'UE_pos', 'UE_TB_SINR_dB');
    end
    
    % plot by cell
    cell_list = sort(unique(UE_attached_eNodeB));
    figure  % TB SINR CDF
    hold on
    lgd_txt = strings(1, length(cell_list));
    for c = 1 : length(cell_list)
        temp = UE_TB_SINR_dB(2:end, UE_attached_eNodeB == cell_list(c));
        h = cdfplot(mean(temp, 1));
        set(h, 'LineWidth', 1.5)
        lgd_txt(c) = "Cell " + cell_list(c);
    end
    legend(lgd_txt, 'Location', 'NW')
    xlim([0, 30])
    hold off
    fname_parts = split(file_name, ".");
    title(replace(fname_parts{1}, "_", " "))
    savefig(fullfile(parent_dir, temp_data_folder, fname_parts{1}))
    
    % plot SINR hotmap
%     x_lim = [prctile(UE_pos(1,:),0.5)-100, prctile(UE_pos(1, :),99.5)+100];
%     y_lim = [prctile(UE_pos(2,:),0.5)-100, prctile(UE_pos(2, :),99.5)+100];
    x_lim = [-2100, 2100];
    y_lim = [-2100, 2100];
    mk_size = 9;
    figure
    xlim(x_lim)
    ylim(y_lim)
    hold on
    scatter(UE_pos(1, :), UE_pos(2, :), mk_size, ...
        mean(UE_TB_SINR_dB(2:end, :), 1), 'square', 'filled');
    xlabel('X position (m)', 'FontSize', 10)
    ylabel('Y position (m)', 'FontSize', 10)
    h = colorbar;
    caxis([0, 30]);
    ylabel(h, 'SINR in dB')
    hold off
    savefig(fullfile(temp_data_folder, fname_parts{1} + "_sinr_map"))
    
    % plot layout
    f_h = figure;
    f_h = plot_MBSFN(cell_list, x_lim, y_lim, mk_size, f_h);
    savefig(f_h, fullfile(temp_data_folder, fname_parts{1} + "_layout"))
    close all
end

function improve_sector_positions()
    radius = 500;
    % var: sector_assignment, sector_positions, site_pos
    load('TS36942_urban_ISD500_res10_4ring_sector_area.mat');
    UE_pos_shift = size(sector_assignment)/2;
    sector_pos_improved = cell(1, length(sector_positions));
    for i = 1 : length(sector_positions)
        tmp_sec_p = 10 * (sector_positions{i} - flip(UE_pos_shift));
        s_pos = site_pos(:, ceil(i/3))';
        delta = tmp_sec_p - s_pos;
        radius_f = (delta(:, 1).^2 + delta(:, 2).^2 <= radius^2);
        sector_pos_improved{i} = tmp_sec_p(radius_f, :);
    end
    save("TS36942_urban_ISD500_res10_4ring_sector_area.mat", ...
        "sector_pos_improved", "-append")  
end

% it is slow compared to the current function.
function plot_MBSFN_old(cell_list, temp_data_folder, title_txt, ...
    x_lim, y_lim, mk_size)
    blue = [0 0.4470 0.7410];
    orange = [0.8500, 0.3250, 0.0980];
    yellow = [0.9290, 0.6940, 0.1250];
    green = [0.4660, 0.6740, 0.1880];
    % var: sector_assignment, site_pos
    load(fullfile(temp_data_folder, ...
        'TS36942_urban_ISD500_res10_4ring_sector_area.mat'));
    plot_pos = round(site_pos);
    UE_pos_shift = size(sector_assignment)/2;
    outer_site = [1:5, 9:11, 19, 20, 28, 29, 37, 38, 46:48, 54:57, 59:61];
    outer_cell = [outer_site*3-2, outer_site*3-1, outer_site*3];
    figure
    xlim(x_lim)
    ylim(y_lim)
    hold on
    % loop of 7 sites, one color for a site
    for cell_ID = 1 : size(site_pos, 2) * 3
        if ismember(cell_ID, outer_cell)
            continue
        end
        if ismember(cell_ID, cell_list)
            color = blue;
        else
            color = yellow;
        end
        [row, col] = find(sector_assignment == cell_ID);
        sector_pos = [col, row];
        UE_area = 10 * (sector_pos - flip(UE_pos_shift));
        X_arr = UE_area(:, 1);
        Y_arr = UE_area(:, 2);
        h = scatter(X_arr, Y_arr, mk_size, color, 'square', 'filled');
        c = mod(cell_ID, 3) + 1;
        h.MarkerFaceAlpha = c * 0.3 + 0.1;
        t= text(prctile(X_arr, 50), prctile(Y_arr, 50), ...
            num2str(cell_ID), 'FontSize', 10);
        set(t, 'Color', [0.8100, 0.3100, 0.1700]) % deep orange
        set(t, 'FontWeight', 'Bold');
    end
    
    % plot site
    scatter(plot_pos(1, :), plot_pos(2, :), 40, 'k', '<', 'filled');
    scatter(plot_pos(1, :), plot_pos(2, :), 20, 'r', 'o', 'filled');
    
    xlabel('X position (m)', 'FontSize', 10)
    ylabel('Y position (m)', 'FontSize', 10)
    hold off

    savefig(fullfile(temp_data_folder, title_txt))
end