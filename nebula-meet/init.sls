###
# nebula
###

{%- from "nebula-meet/map.jinja" import nebula with context %}
{% if nebula.enabled %}

include:
  - nebula.install

/etc/nebula-meet/ca.crt:
  file.managed:
    - source: salt://nebula-meet/cert/ca.crt
    - makedirs: True
    - user: root
    - group: root
    - mode: "0644"

/etc/nebula-meet/{{ grains['id'] }}.crt:
  file.managed:
    - source: salt://nebula-meet/cert/{{ grains['id'] }}.crt
    - makedirs: True
    - user: root
    - group: root
    - mode: "0644"

/etc/nebula-meet/{{ grains['id'] }}.key:
  file.managed:
    - source: salt://nebula-meet/cert/{{ grains['id'] }}.key
    - makedirs: True
    - user: root
    - group: root
    - mode: "0640"

{% if nebula.loophole.enabled %}
generate_ssh_host_ed25519_key:
  cmd.run:
    - name: ssh-keygen -t ed25519 -q -N "" -f /etc/nebula-meet/ssh_host_ed25519_key
    - unless: test -f /etc/nebula-meet/ssh_host_ed25519_key
    - require_in:
        - file: /etc/nebula-meet/config.yml
{% endif %}

/etc/nebula-meet/config.yml:
  file.managed:
    - source:
      - salt://nebula-meet/files/{{ grains['id'] }}-config.yml.jinja
      - salt://nebula-meet/files/config.yml.jinja
    - makedirs: True
    - template: jinja
    - user: root
    - group: root
    - mode: "0644"
    - require:
        - file: /etc/nebula-meet/ca.crt
        - file: /etc/nebula-meet/{{ grains['id'] }}.crt
        - file: /etc/nebula-meet/{{ grains['id'] }}.key

systemd-reload-nebula-meet:
  cmd.run:
    - name: systemctl --system daemon-reload
    - onchanges:
      - file: nebula-meet-service-file

nebula-meet-service-file:
  file.managed:
    - source: salt://nebula-meet/files/nebula.service
    - name: /etc/systemd/system/nebula-meet.service
    - require:
        - file: /etc/nebula-meet/config.yml

nebula-meet-service:
  service.running:
    - enable: True
    - running: True
    #- reload: True
    - name: nebula-meet
    - require:
      - file: nebula-meet-service-file
      - file: /etc/nebula-meet/config.yml
      - pkg: nebula-pkg
    - watch:
        - file: /etc/nebula-meet/config.yml
        - cmd: systemd-reload-nebula-meet

{% else %}
{# remove old config to allow migration to new file destination #}
/etc/nebula-meet/ca.crt:
  file.absent
/etc/nebula-meet/{{ grains['id'] }}.crt:
  file.absent
/etc/nebula-meet/{{ grains['id'] }}.key:
  file.absent
/etc/nebula-meet/config.yml:
  file.absent
/etc/systemd/system/nebula-meet.service:
  file.absent

{% endif %}