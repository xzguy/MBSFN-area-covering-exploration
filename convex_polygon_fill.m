function [intersect_y, x_lim] = convex_polygon_fill(POI)
POI = check_POI_format(POI);
proj_folder = "MBSFN area multiple coverage";
folder = fullfile(proj_folder, "floor_fill_data");
if ~exist(folder, 'dir')
    mkdir(folder)
end
hash_file = POI_HASH(POI);
if isfile(fullfile(folder, hash_file+".mat"))
    load(fullfile(folder, hash_file+".mat"), 'intersect_y', 'x_lim')
else
    x_min = min(POI(1, :));
    x_max = max(POI(1, :));
    intersect_y = nan(2, x_max - x_min + 1);
    for x = x_min : x_max
        cnt = 0;
        y_lim = nan(1, 2);
        for p = 1 : size(POI, 2)
            x1 = POI(1, p);        
            y1 = POI(2, p);
            if p == size(POI, 2)
                x2 = POI(1, 1);
                y2 = POI(2, 1);
            else
                x2 = POI(1, p+1);
                y2 = POI(2, p+1);
            end
            if (x1 - x) * (x2 - x) < 0
                cnt = cnt + 1;
                slope = (y2 - y1) / (x2 - x1);
                y_lim(cnt) = slope*(x - x1) + y1;
            elseif (x1 - x) == 0 && (x2 - x) ~= 0
                cnt = cnt + 1;
                y_lim(cnt) = y1;
            elseif (x1 - x) ~= 0 && (x2 - x) == 0
                cnt = cnt + 1;
                y_lim(cnt) = y2;
            elseif (x1 - x) == 0 && (x2 - x) == 0
                cnt = cnt + 1;
                y_lim(cnt) = y1;
                cnt = cnt + 1;
                y_lim(cnt) = y2;
            end
        end
        y_min = min(y_lim);
        y_max = max(y_lim);
        intersect_y(:, x - x_min+1) = [y_min, y_max]';
    end
    x_lim = [x_min, x_max];
    intersect_y = round(intersect_y);
    x_lim = round(x_lim);
    save(fullfile(folder, hash_file+".mat"), 'intersect_y', 'x_lim');
end
end

function hash_code = POI_HASH(POI)
small_prime = 65537;
large_prime = 433494437; 
x = 0;
y = 0;
for i = 1 : size(POI, 2)
    p = mod(i, 4) + 1;  % p is from 1:4
    x = x + mod((POI(1, i) + 1) * small_prime^p, large_prime);
    y = y + mod((POI(2, i) + 1) * small_prime^p, large_prime);
end
hash_code = "POI_HASH_" + num2str(x) + "&" + num2str(y) + ...
    "_" + size(POI, 2) + "gon";
end  

function POI = check_POI_format(POI)
if length(size(POI)) ~= 2
    error("POI should have only 2 dimensions.")
end
if size(POI, 1) ~= 2
    POI = POI';
end
if size(POI, 2) < 3
    error("POI should have at least 3 points.")
end
end