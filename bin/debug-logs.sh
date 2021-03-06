#!/usr/bin/env bash
#
# Simple script to get all logs, descriptions, events from selected namespace.
# Useful for debugging.
#

SERVICE="service"
DEPLOYMENT="deployment"
INGRESS="ingress"


kcontext=`kubectl config current-context`
NS=`kubectl config view -o jsonpath="{.contexts[?(@.name==\"$kcontext\")].context.namespace}"`

if [ $# = '1' ]; then
    NAMESPACE=$1
else
    NAMESPACE=$NS
fi

echo "Generating debug log for namespace $NAMESPACE"
POD_LIST=$(kubectl -n=${NAMESPACE} get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')

# Go through all pods and get containers for each pod. Get logs from these containers
E_TIME=`date`

OUT=/tmp/log-template.html
TOC=/tmp/log-toc.html

rm -fr $TOC $OUT 

for pod in ${POD_LIST}; do
  echo "Generating $pod logs"
  echo "<h2><a id=\"${pod}\">Pod ${pod} </a></h2>" >> $OUT 

  echo "<li><a href=\"#${pod}\">${pod}</a></li>" >> $TOC 

  containers=$(kubectl -n=${NAMESPACE} get pod ${pod} -o jsonpath='{.spec.containers[*].name}' | tr " " "\n")
  echo "<p>Pod description: </p><pre>" >> $OUT
  kubectl -n=${NAMESPACE} describe pod ${pod} >> $OUT
  echo "</pre><br><p><a href=\"#toc\">Back to Index</a></p>" >> $OUT


  for container in ${containers}; do
    echo "<h3>Logs for container: $container</h3><br><pre>" >> $OUT
    kubectl -n=${NAMESPACE} logs ${pod} ${container} | head -1000 >> $OUT
    echo "</pre><br><hr>" >> $OUT 
  done

done

FINAL=/tmp/log.html


cat >$FINAL <<EOF 
<html>
<h1>Debug Output for namespace ${NAMESPACE} taken at $E_TIME</h1>
<br>
<h1><a id="toc">Pods</a></h1>
<ul>
EOF

cat >>$FINAL $TOC

echo "</ul ><hr>" >> $FINAL 

cat >>$FINAL $OUT

cat >>$OUT <<EOF
</html>
EOF

echo "open file://${FINAL} in your browser"
