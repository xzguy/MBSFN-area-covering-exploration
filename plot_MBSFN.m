function f_h = plot_MBSFN(cell_list, x_lim, y_lim, mk_size, f_h, varargin)
    blue = [0 0.4470 0.7410];
    yellow = [0.9290, 0.6940, 0.1250];
    outer_site = [1:5, 9:11, 19, 20, 28, 29, 37, 38, 46:48, 54:57, 59:61];
    outer_cell = [outer_site*3-2, outer_site*3-1, outer_site*3];
    cell_avoid_list = outer_cell;
    if isempty(varargin)
        clr = blue;
    else
        clr = varargin{1};
        if length(varargin) > 1
            cell_avoid_list = [varargin{2}, outer_cell];
        end
    end
    % var: sector_pos_improved, site_pos
    load('TS36942_urban_ISD500_res10_4ring_sector_area.mat', ...
        'sector_pos_improved', 'site_pos');
    plot_pos = round(site_pos);
    
    figure(f_h)
    xlim(x_lim)
    ylim(y_lim)
    hold on
    % loop of 7 sites, one color for a site
    for cell_ID = 1 : size(site_pos, 2) * 3
        if ismember(cell_ID, cell_avoid_list)
            continue
        end
        if ismember(cell_ID, cell_list)
            color = clr;
        else
            color = yellow;
        end
        UE_area = sector_pos_improved{cell_ID};
        X_arr = UE_area(:, 1);
        Y_arr = UE_area(:, 2);
        h = scatter(X_arr, Y_arr, mk_size, color, 'square', 'filled');
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
    
    xlabel('X position (m)', 'FontSize', 10)
    ylabel('Y position (m)', 'FontSize', 10)
    hold off
end