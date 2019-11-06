local k = import 'ksonnet/ksonnet.beta.4/k.libsonnet';
local list = import 'telemeter/lib/list.libsonnet';

local app = (import '../kubernetes/conprof.libsonnet') + {
  conprof+:: {
    namespace:: '${NAMESPACE}',
    image:: '${IMAGE}:${IMAGE_TAG}',
    version:: '${IMAGE_TAG}',
    replicas:: '${{REPLICAS}}',

    service+: {
      metadata+: {
        annotations+: {
          'service.alpha.openshift.io/serving-cert-secret-name': 'conprof-tls',
        },
      },
      spec+: {
        ports: [
          { name: 'https', port: 443, targetPort: 443 },
        ],
      },
    },

    local statefulset = k.apps.v1.statefulSet,
    local volume = statefulset.mixin.spec.template.spec.volumesType,
    local container = statefulset.mixin.spec.template.spec.containersType,
    local volumeMount = container.volumeMountsType,

    statefulset+: {
      spec+: {
        template+: {
          spec+: {
            containers+: [super.containers[0] {
              args+: '--web.listen-address=127.0.0.1:8080',
            }] + [
              container.new('proxy', '${PROXY_IMAGE}:${PROXY_IMAGE_TAG}') +
              container.withArgs([
                '-provider=openshift',
                '-https-address=:%d' % $.conprof.service.spec.ports[0].targetPort,
                '-http-address=',
                '-email-domain=*',
                '-upstream=http://localhost:8080',
                '-openshift-service-account=prometheus-telemeter',
                '-openshift-sar={"resource": "namespaces", "verb": "get", "name": "${NAMESPACE}", "namespace": "${NAMESPACE}"}',
                '-openshift-delegate-urls={"/": {"resource": "namespaces", "verb": "get", "name": "${NAMESPACE}", "namespace": "${NAMESPACE}"}}',
                '-tls-cert=/etc/tls/private/tls.crt',
                '-tls-key=/etc/tls/private/tls.key',
                '-client-secret-file=/var/run/secrets/kubernetes.io/serviceaccount/token',
                '-cookie-secret-file=/etc/proxy/secrets/session_secret',
                '-openshift-ca=/etc/pki/tls/cert.pem',
                '-openshift-ca=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt',
              ]) +
              container.withPorts([
                { name: 'https', containerPort: $.conprof.service.spec.ports[0].targetPort },
              ]) +
              container.withVolumeMounts(
                [
                  volumeMount.new('secret-conprof-tls', '/etc/tls/private'),
                  volumeMount.new('secret-conprof-proxy', '/etc/proxy/secrets'),
                ]
              ),
            ],

            serviceAccount: 'prometheus-telemeter',
            serviceAccountName: 'prometheus-telemeter',
            volumes+: [
              { name: 'secret-conprof-tls', secret: { secretName: 'conprof-tls' } },
              { name: 'secret-conprof-proxy', secret: { secretName: 'conprof-proxy' } },
            ],
          },
        },
      },
    },
  },
};

{
  apiVersion: 'v1',
  kind: 'Template',
  metadata: {
    name: 'conprof',
  },
  objects: [
    app.conprof[name]
    for name in std.objectFields(app.conprof)
  ],
  parameters: [
    { name: 'NAMESPACE', value: 'telemeter' },
    { name: 'IMAGE', value: 'quay.io/conprof/conprof' },
    { name: 'IMAGE_TAG', value: 'v0.1.0-dev' },
    { name: 'REPLICAS', value: '1' },
    { name: 'PROXY_IMAGE', value: 'openshift/oauth-proxy' },
    { name: 'PROXY_IMAGE_TAG', value: 'v1.1.0' },
  ],
}
