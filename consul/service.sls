{%- from slspath+"/map.jinja" import consul with context -%}

consul-init-env:
  file.managed:
    {%- if grains['os_family'] == 'Debian' %}
    - name: /etc/default/consul
    {%- else %}
    - name: /etc/sysconfig/consul
    - makedirs: True
    {%- endif %}
    - user: root
    - group: root
    - mode: 0644
    - contents:
      - CONSUL_USER={{ consul.user }}
      - CONSUL_GROUP={{ consul.group }}

consul-init-file:
  file.managed:
    {%- if salt['test.provider']('service').startswith('systemd') %}
    - source: salt://{{ slspath }}/files/consul.service
    - name: /etc/systemd/system/consul.service
    - template: jinja
    - context:
        user: {{ consul.user }}
        group: {{ consul.group }}
    - mode: 0644
    {%- elif salt['test.provider']('service') == 'upstart' %}
    - source: salt://{{ slspath }}/files/consul.upstart
    - name: /etc/init/consul.conf
    - mode: 0644
    {%- else %}
    - source: salt://{{ slspath }}/files/consul.sysvinit
    - name: /etc/init.d/consul
    - mode: 0755
    {%- endif %}

{%- if consul.firewalld_config %}
consul-firewalld-service:
  firewalld.service:
    - name: consul
    - ports:
      {%- for service, port in consul.ports.items() %}
        {%- if port != -1 %}
        {%- if service in consul.tcp_ports %}
      - {{ port }}/tcp
        {%- endif %}
        {%- if service in consul.udp_ports %}
      - {{ port }}/udp
        {%- endif %}
        {%- endif %}
      {%- endfor %}
consul-firewalld-zone:
  firewalld.present:
    - name: public
    - services:
      - consul
    - require:
      - consul-firewalld-service
{%- endif %}
{%- if consul.service %}

consul-service:
  service.running:
    - name: consul
    - enable: True
    - watch:
      - file: consul-init-env
      - file: consul-init-file

{%- endif %}
