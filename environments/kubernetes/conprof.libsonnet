{
  conprof:: (import 'conprof/conprof.libsonnet') {
    local conprof = self,

    name:: 'conprof',
    namespace:: $._config.namespace,
    image:: 'quay.io/brancz/conprof:v0.1.0-dev',
    version:: 'v0.1.0-dev',

    rawconfig::
      {
        scrape_configs: [{
          job_name: 'conprof',
          kubernetes_sd_configs: [{
            namespaces: { names: conprof.namespaces },
            role: 'pod',
          }],
          relabel_configs: [
            {
              action: 'keep',
              regex: 'thanos.*',
              source_labels: ['__meta_kubernetes_pod_name'],
            },
            {
              action: 'keep',
              regex: 'http',
              source_labels: ['__meta_kubernetes_pod_container_port_name'],
            },
          ],
          scrape_interval: '1m',
          scrape_timeout: '1m',
        }],
      },
  },
}
