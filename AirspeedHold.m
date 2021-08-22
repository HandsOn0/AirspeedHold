%clear A D datagram Data Oldstat pitch integral Err ias i K it throttle elev pitch_trim
%u2 = udp('127.0.0.1','LocalPort',49003);
%u2.EnablePortSharing = 'on';
%fopen(u2);
n=2;
No_command=single(-999);
%u = udp('127.0.0.1',49000);
%fopen(u);
header=uint8([68 65 84 65 0]);
gear_brake_index=uint8([14 0 0 0]);
gear_brake_cmd=[No_command 0 No_command No_command 0 No_command No_command No_command];
throttle_cmd_index=uint8([25 0 0 0]);
throttle=0;
%throttle_cmd=[throttle throttle No_command No_command No_command No_command No_command No_command];
primary_ctr_index=uint8([11 0 0 0]);
sec_ctr_index=uint8([13 0 0 0]);
datagram=serialize(header,gear_brake_index,gear_brake_cmd);
fwrite(u,datagram);
IASRef=200;
K=[0.5 0 1.5];
Integral=0;
Oldstat=[0 0];

while(true)
    tic
   l=0;
   while(l~=5+n*36)
 A=fread(u2,5+n*9*4);
   [l dummy]=size(A);
   end
Data=zeros(n,8);
for i=1:n
    for j=2:9  
Data(i,j-1)=typecast(uint8(A(6+(i-1)*36+(j-1)*4:(i-1)*36+6+(j-1)*4+3)),'single');
    end
end
ias(it)=Data(1,1);
Err=IASRef-ias(it);
D(it)=[ias(it) Oldstat]*[3 -4 1]';
Oldstat(2)=Oldstat(1);
Oldstat(1)=ias(it);
Integral=Integral+Err;
throttle=throttle+K*[Err;Integral;D(it)];
if throttle>1
    throttle=1;
end
if throttle<0
    throttle=0;
end

throttle_cmd=[throttle throttle No_command No_command No_command No_command No_command No_command];
datagram=serialize(header,throttle_cmd_index,throttle_cmd);
fwrite(u,datagram);
T(it)=toc;
if T(it)>0.1
    it=it+1;
    %t(it)=t(it-1)+T(it);
end
end
function output=serialize(varargin)
[dummy n]=size(varargin);
id=1;
for i=1:n
w=typecast(varargin{i},'uint8');
[x y]=size(w);
output(id:id+y-1)=w;
id=id+y;
end
end