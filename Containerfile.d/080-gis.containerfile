# ── Spatial / GIS tooling ─────────────────────────────────────────────────────
RUN rpm-ostree install \
    gdal \
    gdal-devel \
    gdal-libs \
    python3-gdal \
    mapnik \
    mapnik-devel \
    python3-mapnik \
    qgis \
    grass \
    grass-devel \
    proj \
    proj-devel \
    geos \
    geos-devel \
    libspatialite \
    libspatialite-devel \
    spatialite-tools \
    && ostree container commit
