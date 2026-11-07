agents_cmd() {
    if ojuny_is_json; then
        ojuny_agents_json
        return 0
    fi
    ojuny_agents_md
}

catalog_cmd() {
    if ojuny_is_json; then
        local catalog
        catalog="$(ojuny_catalog_json)"
        jq -cn --argjson commands "$catalog" \
            '{schema:1,command:"commands",ok:true,data:{commands:$commands},meta:{}}'
        return 0
    fi
    ojuny_catalog_human
}
