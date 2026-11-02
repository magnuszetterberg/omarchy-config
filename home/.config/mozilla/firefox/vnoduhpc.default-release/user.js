// WebGPU on the NVIDIA dGPU: present via CPU readback. The zero-copy path hands
// NVIDIA dmabufs to the Intel-side compositor, which crashes the GPU process.
user_pref("dom.webgpu.enabled", true);
user_pref("dom.webgpu.allow-present-without-readback", false);
