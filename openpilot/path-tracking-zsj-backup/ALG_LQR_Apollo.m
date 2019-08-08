function steer_cmd = ALG_LQR_Apollo(veh_pose, trajref, lqr_apollo_params,...
    veh_params, steer_state, time_step)
% ��Apollo LQR�㷨��������ǰ��ƫ��
% ���õĳ���ģ��model LQR: 

% ���:
% steer_cmd     : ����ǰ��ƫ��, rad

% ����:
% veh_pose      : ������ǰλ��[x, y, theta]
% trajref       : ����·��[X, Y, Theta, Radius]
% lqr_apollo_params    : LQR����
% veh_params    : ��������
% steer_state   : ��ǰǰ��ƫ��, rad
% time_step     : ����ʱ�䲽��, s

% 1. ���㳵����ǰλ��������·���ϵ�ͶӰ��λ��
[~, index] = calc_nearest_point(veh_pose, trajref);
ref_pose = calc_proj_pose(veh_pose(1:2), trajref(index, 1:3),...
    trajref(index + 1, 1:3));

% 2. ����ο����ǰ��ƫ��ǰ��������
ref_index = index + lqr_apollo_params.ref_index;
ref_radius = trajref(ref_index, 4);

% 2.1 Feedforward angle update
 kv=lqr_apollo_params.lr*lqr_apollo_params.mass/2/lqr_apollo_params.cf/...
      veh_params.wheel_base - lqr_apollo_params.lf*lqr_apollo_params.mass...
      /2/lqr_apollo_params.cr/veh_params.wheel_base;
 k=trajref(index,5);  % curvature
 v=veh_params.velocity;
 steer_feedforward=atan(veh_params.wheel_base*k + kv *v*v*k);
 steer_feedforward=angle_normalization(steer_feedforward);
  
% Todo: gain scheduler for higher speed steering

% 3. ��LQR����ǰ��ƫ�Ƿ���������
delta_x = (veh_pose - ref_pose)';
steer_feedbackward = calc_lqr_Apollo_feedbackward(trajref, delta_x, ...
    lqr_apollo_params, index, veh_params, veh_pose);

% 4. ��������ǰ��ƫ�ǧ�
steer_cmd = steer_feedforward + steer_feedbackward;

% 5. ��������ǰ��ƫ�ǧ�
steer_cmd = limit_steer_by_angular_vel(steer_cmd, steer_state,...
    veh_params.max_angular_vel, time_step);

steer_cmd = limit_steer_angle(steer_cmd, veh_params.max_steer_angle);

