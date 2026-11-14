# Show current firstboot/network information at interactive login, including
# after the automatic resize reboot. Never apply configuration from a profile.
if [ -t 1 ] && [ -x /usr/local/sbin/bmo-firstboot ] && [ -f /var/lib/bmo/firstboot.done ]; then
    /usr/local/sbin/bmo-firstboot --summary || true
fi
