#!/bin/sh

VIMDOC="${PANVIMDOC:-./panvimdoc}"

if [ ! -d "${VIMDOC}" ]; then
    echo 'could not find panvimdoc directory' >&2
    exit 1
fi

"${VIMDOC}/panvimdoc.sh"  \
    --project-name 'zshow'  \
    --input-file 'README.md'  \
    --toc 'true'  \
    --dedup-subheadings 'false'  \
    --demojify 'true'  \
    --doc-mapping-project-name 'false'  \
    --scripts-dir "${VIMDOC}/scripts"  \
    --shift-heading-level-by -1 \
