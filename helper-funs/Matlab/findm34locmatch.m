function [elec] = findm34locmatch(wanted)

eeglab('nogui');
m34 = readlocs('Custom_M34_V3_Easycap_Layout_EEGlab.sfp');
tt = readlocs('standard-10-5-cap385.elp');

ttXYZ = [[tt.X]', [tt.Y]', [tt.Z]'] ./ 85; %cust is normalized
custXYZ = [[m34.X]', [m34.Y]', [m34.Z]'];
idx = ismember({tt.labels}, wanted);
distances = pdist2(ttXYZ(idx, :), custXYZ, 'euclidean');
[~, wantedidx] = min(distances);
elec = m34(wantedidx).labels;
end
