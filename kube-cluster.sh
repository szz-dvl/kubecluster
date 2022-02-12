#!/bin/bash

file=kube-cluster.yml
list="false"
workers=$(docker-compose -f $file ps 2>/dev/null | grep "worker" | wc -l)
controllers=$(docker-compose -f $file ps 2>/dev/null | grep "controller" | wc -l)

if [ $workers -eq 0 ]; then workers=1; fi
if [ $controllers -eq 0 ]; then controllers=1; fi

parse_long() {
	
	content=$1

	val=${content#*=}
        opt=${content%=$val}

	echo "$opt,$val"

}

flush_toggle() {
	if [ "$1" != -* ]; then
                shift;
        fi
}

error() {
	
	echo "$0: $1"
	exit $2

}

optspec="f:w:c:-:bls"

while getopts "$optspec" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                workers=*)
	            IFS="," read key val <<< "$(parse_long $OPTARG)"
		    workers=$val
                    ;;
                controllers=*)
	            IFS="," read key val <<< "$(parse_long $OPTARG)"
		    controllers=$val
                    ;;
                file=*)
	            IFS="," read key val <<< "$(parse_long $OPTARG)"
		    file=$val
		    ;;
                list)
		    list="true"
	            flush_toggle $2
                    ;;
                stop)
		    stop="true"
		    flush_toggle $2
                    ;;
                *)
		    IFS="," read key val <<< "$(parse_long $OPTARG)"
                    if [ "$OPTERR" = 1 ]; then
			error "illegal option -- ${key}" -1
                    fi
                    ;;
            esac;;
        w)
	    workers=$OPTARG
            ;;
        c)
	    controllers=$OPTARG
            ;;
        f)
	    file=$OPTARG
            ;;
        l)
	    list="true"
	    flush_toggle $2
            ;;
        s)
	    stop="true"
	    flush_toggle $2
            ;;
	*)
	    error "unexpected error" -2
	    ;;
    esac
done

if [ -z "$K8S_RELEASE" ]; then
	export K8S_RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
fi

if [ "$list" == "true" ]; then
	docker-compose -f $file ps
	exit 0
fi

if [ "$stop" == "true" ]; then
	docker-compose -f $file down
	exit 0
fi

#running=$(docker-compose -f $file ps 2>/dev/null | tail -n +2)
docker-compose -f $file up -d --scale kube_worker=$workers --scale kube_controller=$controllers
