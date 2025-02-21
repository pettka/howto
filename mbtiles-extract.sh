curl https://raw.githubusercontent.com/siwekm/czech-geojson/refs/heads/master/kraje.json | jq '{
  type: "Feature",
  geometry: {
    type: "Polygon",
    coordinates: (.features[] | select(.nationalCode == "19") | .geometry.coordinates)
  },
  properties: {
    name: (.features[] | select(.nationalCode == "19") | .name)
  }
}' > prague.json

osmium extract -p prague.json -o /data/openmaptiles/data/cz-prague.osm.pbf /data/openmaptiles/data/czech-republic.osm.pbf


time docker run --rm --name planetiler -ti -e JAVA_TOOL_OPTIONS="-Xmx24g" -v "/data/openmaptiles/data":/data ghcr.io/onthegomap/planetiler:latest ---osm-path=/data/cz-prague.osm.pbf --nodemap-type=array --storage=mmap --output=/data/cz-prague-$(date '+%y%m%d').mbtiles --download --area=czech-republic

docker run --rm -it -v /data/openmaptiles/data/:/data -p 8888:8080 maptiler/tileserver-gl:latest --file cz-prague-250221.mbtiles
