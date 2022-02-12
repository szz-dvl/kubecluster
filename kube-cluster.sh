#!/bin/bash

workers=1
controllers=1
file=kube-cluster.yml
controller_update="false"
worker_update="false"
list="false"

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

optspec="f:w:c:-:bl"

while getopts "$optspec" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                workers=*)
	            IFS="," read key val <<< "$(parse_long $OPTARG)"
		    workers=$val
	    	    worker_update="true"
                    ;;
                controllers=*)
	            IFS="," read key val <<< "$(parse_long $OPTARG)"
		    controllers=$val
		    controller_update="true"
                    ;;
                file=*)
	            IFS="," read key val <<< "$(parse_long $OPTARG)"
		    file=$val
		    ;;
                list)
	            IFS="," read key val <<< "$(parse_long $OPTARG)"
		    list="true"
                    ;;
                *)
		    IFS="," read key val <<< "$(parse_long $OPTARG)"
                    if [ "$OPTERR" = 1 ]; then
			error "illegal option -- ${key}" -1
                    fi
                    ;;
            esac;;
        w)
	    worker_update="true"
	    workers=$OPTARG
            ;;
        c)
	    controller_update="true"
	    controllers=$OPTARG
            ;;
        f)
	    file=$OPTARG
            ;;
        l)
	    list="true"
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

CMD="docker-compose -f $file up -d"

if [ "$worker_update" == "true" ]; then
	CMD+=" --scale kube_worker=$workers"
fi

if [ "$controller_update" == "true" ]; then
	CMD+=" --scale kube_controller=$controllers"
fi

if [ "$worker_update" == "true" ] || [ "$controller_update" == "true" ]; then
	$CMD
else
	running=$(docker-compose -f $file ps 2>/dev/null | tail -n +2)
	
	if [ -z "$running" ]; then
		$CMD
	else
		error "nothing to do ... " -4
	fi
fi
