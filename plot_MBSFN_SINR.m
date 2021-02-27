function [f_h, perc] = plot_MBSFN_SINR(area, SINR, x_lim, y_lim, ...
    mk_size, f_h, varargin)
    blue = [0 0.4470 0.7410];
    yellow = [0.9290, 0.6940, 0.1250];    
    brown = [0.75, 0.75, 0];
    black = [0.25, 0.25, 0.25];
    
    temp_data_folder = "MBSFN_Area_7site";
    f_n = temp_data_folder + "_" + lower(area) + "_outlier_clear.mat";
    load(fullfile(temp_data_folder, f_n), ...
        'UE_attached_eNodeB', 'UE_pos', 'UE_TB_SINR_dB');
    cell_list = sort(unique(UE_attached_eNodeB));
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
        if ismember(cell_ID, cell_list) || ismember(cell_ID, outer_cell)
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
    
    % selected cells
    sinr_avg = mean(UE_TB_SINR_dB(2:end, :), 1);
    if SINR == -Inf         % original SINR value
        scatter(UE_pos(1,:), UE_pos(2,:), mk_size, sinr_avg, 'square', 'filled');
        h = colorbar;
        caxis([0, 30]);
        ylabel(h, 'SINR in dB')
    else
        sinr_f = (sinr_avg >= SINR);
        perc = sum(sinr_f) / length(sinr_f);
        text(1100, -1700, perc*100 + "% in service of the");
        text(1100, -1800, "current 21-cell MBSFN area")
        s1 = scatter(UE_pos(1,sinr_f), UE_pos(2,sinr_f), mk_size, brown, ...
            'square', 'filled');
        s2 = scatter(UE_pos(1,~sinr_f), UE_pos(2,~sinr_f), mk_size, black, ...
            'square', 'filled');
        if ~isempty(varargin)
            POI = varargin{1}; % [X_list; Y_list]
            if size(POI, 2) < 3
                error("At least 3 points to form a polygon.")
            end
            for p = 1 : size(POI, 2)-1
                plot([POI(1, p), POI(1, p+1)], [POI(2, p), POI(2, p+1)],...
                    'r', 'LineWidth', 1.5);
            end
            plot([POI(1, end), POI(1, 1)], [POI(2, end), POI(2, 1)],...
                    'r', 'LineWidth', 1.5);
        end
        legend([s1, s2], "In Service", "Out of Service")
    end
    
    xlabel('X position (m)', 'FontSize', 10)
    ylabel('Y position (m)', 'FontSize', 10)
    hold off
end