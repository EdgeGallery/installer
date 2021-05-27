  create table applcminventory (
        applcm_id varchar(255) not null,
        applcm_name varchar(255) not null,
        applcm_ip varchar(255) not null,
        applcm_port varchar(255) not null,
        user_name varchar(255),
        created_time varchar(200),
        modified_time varchar(200),
        primary key (applcm_id)
    );

    create table apprulemanagerinventory (
        app_rule_manager_id varchar(255) not null,
        apprule_name  varchar(255) not null,
        app_rule_manager_ip varchar(255) not null,
        app_rule_manager_port varchar(255) not null,
        user_name varchar(255),
        created_time varchar(200),
        modified_time varchar(200),
        primary key (app_rule_manager_id)
    );

    create table appstoreinventory (
        appstore_id varchar(255) not null,
        appstore_ip varchar(255) not null,
        appstore_port varchar(255) not null,
        appstore_name varchar(255),
        appstore_reponame varchar(255),
        appstore_repo varchar(255),
        appstore_repousername varchar(255) not null,
        appstore_repopassword varchar(255) not null,
        producer varchar(255),
        created_time varchar(200),
        modified_time varchar(200),
        primary key (appstore_id)
    );

    create table apprepoinventory (
        repo_id varchar(255) not null,
        repo_name varchar(255),
        repo_endpoint varchar(255) not null,
        repo_username varchar(255) not null,
        repo_password varchar(255) not null,
        primary key (repo_id)
    );

    create table mechostinventory (
        mechost_id varchar(255) not null,
        mechost_ip varchar(255) not null,
        applcm_ip varchar(255) not null,
        apprule_ip varchar(255),
        mechost_name varchar(255) not null,
        zip_code varchar(200),
        city varchar(255) not null,
        address varchar(255) not null,
        affinity varchar(255),
        user_name varchar(255),
        coordinates varchar(128),
        vim varchar(128),
        config_upload_status varchar(255),
        -- config_file_path varchar(2000),
        created_time varchar(200),
        modified_time varchar(200),
        primary key (mechost_id)
    );

    create table mechwcapabilityinventory (
        capability_id varchar(255) not null,
        mechost_id varchar(255) not null,
        hw_type varchar(200),
        hw_vendor varchar(255),
        hw_model varchar(255),
        created_time varchar(200),
        modified_time varchar(200),
        primary key (capability_id),
        constraint fk_mechost
          foreign key(mechost_id)
        	  references mechostinventory(mechost_id)
    );

    create table mecapplicationinventory (
        appinstance_id varchar(255) not null,
        mechost_id varchar(255) not null,
        tenant_id varchar(255) not null,
        app_name varchar(255) not null,
        package_id varchar(255) not null,
        capabilities varchar(255),
        status varchar(255) not null,
        primary key (appinstance_id),
        constraint fk_mechost_app
          foreign key(mechost_id)
        	  references mechostinventory(mechost_id)
    );

    create table tenantinventory (
        tenant_id  varchar(255) not null,
        applcm_count int,
        app_rule_manager_count int,
        appstore_count int,
        mechost_count int,
        mechwcapability_count int,
        mecapplication_count int,
        appdrule_count int,
        appdnsrule_count int,
        apptrafficrule_count int,
        trafficfilter_count int,
        apprepo_count int,
        primary key (tenant_id)
    );

    create table tunnelinfoinventory (
        tunnel_info_id varchar(255) not null,
        tunnel_type varchar(255) not null,
        tunnel_dst_address varchar(255) not null,
        tunnel_src_address varchar(255) not null,
        tunnel_specific_data varchar(255) not null,
        tenant_id  varchar(255) not null,
        primary key (tunnel_info_id)
    );

    create table appdruleinventory (
        tenant_id varchar(255) not null,
        app_instance_id varchar(255) not null,
        appd_rule_id varchar(255) not null,
        status varchar(255),
        app_name varchar(255) not null,
        app_support_mp1 boolean,
        primary key (appd_rule_id)
    );

    create table appdnsruleinventory (
        dns_rule_id varchar(255) not null,
        app_instance_id varchar(255) not null,
        domain_name  varchar(255) not null,
        ip_address_type varchar(255) not null,
        ip_address  varchar(255) not null,
        ttl  varchar(255),
        tenant_id  varchar(255) not null,
        appd_rule_id varchar(255) not null,
        primary key (dns_rule_id),
        constraint fk_appd_dnsrule
          foreign key(appd_rule_id)
            references appdruleinventory(appd_rule_id)
            on delete cascade
    );

    create table apptrafficruleinventory (
        traffic_rule_id varchar(255) not null,
        app_instance_id varchar(255) not null,
        filter_type  varchar(255) not null,
        priority int not null,
        action  varchar(255) not null,
        tenant_id  varchar(255) not null,
        appd_rule_id varchar(255) not null,
        primary key (traffic_rule_id),
        constraint fk_appd_trafficrule
          foreign key(appd_rule_id)
            references appdruleinventory(appd_rule_id)
            on delete cascade
    );

    create table trafficfilterinventory (
        traffic_filter_id varchar(255) not null,
        traffic_rule_id varchar(255) not null,
        src_address array,
        src_port array,
        dst_address array,
        dst_port array,
        protocol array,
        tag array,
        src_tunnel_address array,
        dst_tunnel_address array,
        src_tunnel_port array,
        dst_tunnel_port array,
        qci int,
        dscp int,
        tc int,
        tenant_id  varchar(255) not null,
        primary key (traffic_filter_id),
        constraint fk_appd_trafficfilter
          foreign key(traffic_rule_id)
            references apptrafficruleinventory(traffic_rule_id)
            on delete cascade
    );

    create table trafficfiltersrcaddressinventory (
        traffic_filter_id varchar(255) not null,
        src_address varchar(255) not null,
        constraint fk_appd_trafficfilter_srcaddress
          foreign key(traffic_filter_id)
            references trafficfilterinventory(traffic_filter_id)
            on delete cascade
    );

    create table trafficfilterdstaddressinventory (
        traffic_filter_id varchar(255) not null,
        dst_address varchar(255) not null,
        constraint fk_appd_trafficfilter_dstaddress
          foreign key(traffic_filter_id)
            references trafficfilterinventory(traffic_filter_id)
            on delete cascade
    );

    create table trafficfiltersrcportinventory (
        traffic_filter_id varchar(255) not null,
        src_port varchar(255) not null,
        constraint fk_appd_trafficfilter_srcport
          foreign key(traffic_filter_id)
            references trafficfilterinventory(traffic_filter_id)
            on delete cascade
    );

    create table trafficfilterdstportinventory (
        traffic_filter_id varchar(255) not null,
        dst_port varchar(255) not null,
        constraint fk_appd_trafficfilter_dstport
          foreign key(traffic_filter_id)
            references trafficfilterinventory(traffic_filter_id)
            on delete cascade
    );

    create table trafficfilterprotocolinventory (
        traffic_filter_id varchar(255) not null,
        protocol varchar(255) not null,
        constraint fk_appd_trafficfilter_protocol
          foreign key(traffic_filter_id)
            references trafficfilterinventory(traffic_filter_id)
            on delete cascade
    );

    create table trafficfiltertaginventory (
        traffic_filter_id varchar(255) not null,
        tag varchar(255) not null,
        constraint fk_appd_trafficfilter_tag
          foreign key(traffic_filter_id)
            references trafficfilterinventory(traffic_filter_id)
            on delete cascade
    );

    create table trafficfiltersrctunneladdressinventory (
        traffic_filter_id varchar(255) not null,
        src_tunnel_address varchar(255) not null,
        constraint fk_appd_trafficfilter_srctunneladdress
          foreign key(traffic_filter_id)
            references trafficfilterinventory(traffic_filter_id)
            on delete cascade
    );

    create table trafficfilterdsttunneladdressinventory (
        traffic_filter_id varchar(255) not null,
        dst_tunnel_address varchar(255) not null,
        constraint fk_appd_trafficfilter_dsttunneladdress
          foreign key(traffic_filter_id)
            references trafficfilterinventory(traffic_filter_id)
            on delete cascade
    );

    create table trafficfiltersrctunnelportinventory (
        traffic_filter_id varchar(255) not null,
        src_tunnel_port varchar(255) not null,
        constraint fk_appd_trafficfilter_srctunnelport
          foreign key(traffic_filter_id)
            references trafficfilterinventory(traffic_filter_id)
            on delete cascade
    );

    create table trafficfilterdsttunnelportinventory (
        traffic_filter_id varchar(255) not null,
        dst_tunnel_port varchar(255) not null,
        constraint fk_appd_trafficfilter_dsttunnelport
          foreign key(traffic_filter_id)
            references trafficfilterinventory(traffic_filter_id)
            on delete cascade
    );

    create table dstinterfaceinventory (
        dst_interface_id varchar(255) not null,
        traffic_rule_id varchar(255) not null,
        interface_type varchar(255) not null,
        src_mac_address varchar(255),
        dst_mac_address varchar(255),
        dst_ip_address varchar(255),
        tunnel_info_id varchar(255),
        tenant_id  varchar(255) not null,
        primary key (dst_interface_id),
        constraint fk_appd_dstinterface
          foreign key(traffic_rule_id)
            references apptrafficruleinventory(traffic_rule_id)
            on delete cascade,
        constraint fk_appd_tunnelinfo
          foreign key(tunnel_info_id)
            references tunnelinfoinventory(tunnel_info_id)
            on delete cascade
    );