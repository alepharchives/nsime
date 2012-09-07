%%
%%  Copyright (C) 2012 Saravanan Vijayakumaran <sarva.v@gmail.com>
%%
%%  This file is part of nsime.
%%
%%  nsime is free software: you can redistribute it and/or modify
%%  it under the terms of the GNU General Public License as published by
%%  the Free Software Foundation, either version 3 of the License, or
%%  (at your option) any later version.
%%
%%  nsime is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU General Public License for more details.
%%
%%  You should have received a copy of the GNU General Public License
%%  along with nsime.  If not, see <http://www.gnu.org/licenses/>.
%%

%% Purpose :IP endpoint state record
%% Author : Saravanan Vijayakumaran

-record(nsime_ip_endpoint_state,
        {
          local_address               :: inet:ip_address(),
          local_port                  :: inet:port_number(),
          peer_address                :: inet:ip_address(),
          peer_port                   :: inet:port_number(),
          bound_netdevice             :: pid(),
          receive_callback            :: nsime_callback(),
          icmp_callback               :: nsime_callback(),
          destroy_callback            :: nsime_callback()
        }).
