###
# This is a collection of helper functions I source in my zsh shell
###

alias minikube-image-ls='minikube image ls --format table'


function kubectl-ports() {
  kubectl get svc --all-namespaces -o json | jq '.items | sort_by(.metadata.namespace, .metadata.name) | map( { "\(.metadata.namespace)::\(.metadata.name)": (.spec.ports | map({"\(.name)":"\( .nodePort):\(.targetPort)"}) | add ) }) | add'
}


function helm-template-split() {
  local output_dir="./helm-template-output"
  local release_name="release-name"
  local chart_path="./chart"
  local use_default_values=true
  local -a extra_args=()
  local -a helm_args=()
  local -a passthrough_args=()

  local usage_text="
Usage: helm-template-split [options]

Runs 'helm template' on the Seneca chart and writes each rendered template to
its own file under the output directory, preserving the chart source path.

Options:
  -o, --output-dir <dir>          Output directory (default: $output_dir)
  --release-name <name>           Helm release name (default: $release_name)
  --chart <path>                  Path to chart (default: $chart_path)
  -f, --values <file>             Additional values file, if not set values files
                                    in working directory detected 
                                    ^\./values([._-].+)?\.yaml$
  --set <key=value>               Set a helm value
  -h, --help                      Show this help message
  [-- | <unknown args>]           Any unrecognised arguments are passed through
                                    to 'helm template' as-is
"

  while [[ -n $1 ]]; do
    local arg=$1
    shift
    case $arg in
      "-h"|"--help")
        echo "$usage_text"
        return 0
        ;;
      "-o"|"--output-dir")
        output_dir=$1
        shift
        ;;
      "--release-name")
        release_name=$1
        shift
        ;;
      "-c"|"--chart")
        chart_path=$1
        shift
        ;;
      "-f"|"--values")
        use_default_values=false
        if [[ ! -f "$1" ]]; then
            echo "Error: values file '$1' does not exist"
            return 1
        fi
        extra_args+=("-f" "$1")
        shift
        ;;
      "--set")
        extra_args+=("--set" "$1")
        shift
        ;;
      *)
        passthrough_args+=("$arg")
        ;;
    esac
  done

  if [[ ! -f "$chart_path/Chart.yaml" ]]; then
    echo "Error: '$chart_path' does not contain a valid Helm chart (Chart.yaml not found)"
    return 1
  fi

  if $use_default_values; then
    while IFS= read -r values_file; do
        helm_args+=("-f" "$values_file")
    done < <(find . -maxdepth 1 -name '*.yaml' | grep -E '^\./values([._-].+)?\.yaml$' | sort || true)
  fi

  helm_args+=("${extra_args[@]}")

  echo "Chart:       $chart_path"
  echo "Release:     $release_name"
  echo "Output dir:  $output_dir"
  echo "Helm args:   ${helm_args[*]}"
  echo ""

  rm -rf "$output_dir"
  mkdir -p "$output_dir"

  helm template "$release_name" "$chart_path" "${helm_args[@]}" "${passthrough_args[@]}" | \
  awk -v outdir="$output_dir" '
  /^---$/ {
      if (outfile) close(outfile)
      outfile = ""
      next
  }
  /^# Source: / {
      # "# Source: " is 10 characters; the rest is the relative template path
      src = substr($0, 11)
      # strip the leading chart-name folder
      sub(/^[^\/]+\//, "", src)
      outfile = outdir "/" src
      dir = outfile
      sub(/\/[^\/]*$/, "", dir)
      system("mkdir -p \"" dir "\"")
      print "---" > outfile
      print $0 > outfile
      next
  }
  outfile != "" {
      print > outfile
  }
  '

  local helm_exit=${pipestatus[1]}
  if [[ $helm_exit -ne 0 ]]; then
    return $helm_exit
  fi

  local file_count
  file_count=$(find "$output_dir" -name "*.yaml" | wc -l | tr -d ' ')
  echo "Done. $file_count file(s) written to $output_dir"
}
