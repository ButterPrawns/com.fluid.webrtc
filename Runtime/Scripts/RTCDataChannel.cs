using System;
using System.Runtime.InteropServices;
using Unity.Collections;
using Unity.Collections.LowLevel.Unsafe;

namespace Unity.WebRTC
{
    /// <summary>
    /// Provides configuration options for the data channel.
    /// </summary>
    /// <seealso cref="RTCPeerConnection.CreateDataChannel(string, RTCDataChannelInit)"/>
    public class RTCDataChannelInit
    {
        /// <summary>
        /// Indicates whether or not the data channel guarantees in-order delivery of messages.
        /// </summary>
        public bool? ordered;
        /// <summary>
        /// Represents the maximum number of milliseconds that attempts to transfer a message may take in unreliable mode..
        /// </summary>
        /// <remarks>
        /// Cannot be set along with <see cref="RTCDataChannelInit.maxRetransmits"/>.
        /// </remarks>
        /// <seealso cref="RTCDataChannelInit.maxRetransmits"/>
        public int? maxPacketLifeTime;
        /// <summary>
        /// Represents the maximum number of times the user agent should attempt to retransmit a message which fails the first time in unreliable mode.
        /// </summary>
        /// <remarks>
        /// Cannot be set along with <see cref="RTCDataChannelInit.maxPacketLifeTime"/>.
        /// </remarks>
        /// <seealso cref="RTCDataChannelInit.maxPacketLifeTime"/>
        public int? maxRetransmits;
        /// <summary>
        /// Provides the name of the sub-protocol being used on the RTCDataChannel.
        /// </summary>
        public string protocol;
        /// <summary>
        /// Indicates whether the RTCDataChannel's connection is negotiated by the Web app or by the WebRTC layer.
        /// </summary>
        public bool? negotiated;
        /// <summary>
        /// Indicates a 16-bit numeric ID for the channel.
        /// </summary>
        public int? id;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct RTCDataChannelInitInternal
    {
        public OptionalBool ordered;
        public OptionalInt maxRetransmitTime;
        public OptionalInt maxRetransmits;
        [MarshalAs(UnmanagedType.LPStr)]
        public string protocol;
        public OptionalBool negotiated;
        public OptionalInt id;

        public static explicit operator RTCDataChannelInitInternal(RTCDataChannelInit origin)
        {
            RTCDataChannelInitInternal dst = new RTCDataChannelInitInternal
            {
                ordered = origin.ordered,
                maxRetransmitTime = origin.maxPacketLifeTime,
                maxRetransmits = origin.maxRetransmits,
                protocol = origin.protocol,
                negotiated = origin.negotiated,
                id = origin.id
            };
            return dst;
        }
    }

    /// <summary>
    /// Represents type of delegate to be called when WebRTC open event is sent.
    /// </summary>
    /// <remarks>
    /// The WebRTC open event is sent to an RTCDataChannel object's onopen event handler when the underlying transport used to send and receive the data channel's messages is opened or reopened.
    /// This event is not cancelable and does not bubble.
    /// </remarks>
    /// <seealso cref="RTCDataChannel.OnOpen"/>
    public delegate void DelegateOnOpen();

    /// <summary>
    /// Represents type of delegate to be called when RTCDataChannel close event is sent.
    /// </summary>
    /// <remarks>
    /// The close event is sent to the onclose event handler on an RTCDataChannel instance when the data transport for the data channel has closed.
    /// Before any further data can be transferred using RTCDataChannel, a new 'RTCDataChannel' instance must be created.
    /// This event is not cancelable and does not bubble.
    /// </remarks>
    /// <seealso cref="RTCDataChannel.OnClose"/>
    public delegate void DelegateOnClose();

    /// <summary>
    /// Represents type of delegate to be called when RTCDataChannel message event is sent.
    /// </summary>
    /// <remarks>
    /// The WebRTC message event is sent to the onmessage event handler on an RTCDataChannel object when a message has been received from the remote peer.
    /// </remarks>
    /// <param name="bytes"></param>
    /// <seealso cref="RTCDataChannel.OnMessage"/>
    public delegate void DelegateOnMessage(byte[] bytes);

    /// <summary>
    /// Represents type of delegate to be called when RTCPeerConnection datachannel event is sent.
    /// </summary>
    /// <remarks>
    /// A datachannel event is sent to an RTCPeerConnection instance when an RTCDataChannel has been added to the connection,
    /// as a result of the remote peer calling RTCPeerConnection.createDataChannel().
    /// </remarks>
    /// <param name="channel"></param>
    /// <seealso cref="RTCPeerConnection.OnDataChannel"/>
    public delegate void DelegateOnDataChannel(RTCDataChannel channel);

    /// <summary>
    /// Delegate to be called when RTCPeerConnection error event is sent.
    /// </summary>
    /// <remarks>
    /// A WebRTC error event is sent to an RTCDataChannel object's onerror event handler when an error occurs on the data channel.
    /// The RTCErrorEvent object provides details about the error that occurred; see that article for details.
    /// This event is not cancelable and does not bubble.
    /// </remarks>
    /// <seealso cref="RTCDataChannel.OnError"/>
    public delegate void DelegateOnError(RTCError error);

    /// <summary>
    /// Represents a network channel which can be used for bidirectional peer-to-peer transfers of arbitrary data.
    /// </summary>
    /// <remarks>
    /// RTCDataChannel interface represents a network channel which can be used for bidirectional peer-to-peer transfers of arbitrary data.
    /// Every data channel is associated with an RTCPeerConnection, and each peer connection can have up to a theoretical maximum of 65,534 data channels.
    ///
    /// To create a data channel and ask a remote peer to join you, call the RTCPeerConnection's createDataChannel() method.
    /// The peer being invited to exchange data receives a datachannel event (which has type RTCDataChannelEvent) to let it know the data channel has been added to the connection.
    /// </remarks>
    /// <example>
    ///     <code lang="cs"><![CDATA[
    ///         var initOption = new RTCDataChannelInit();
    ///         var peerConnection = new RTCPeerConnection();
    ///         var dataChennel = peerConnection.createDataChannel("test channel", initOption);
    ///
    ///         dataChennel.OnMessage = (event) => {
    ///             Debug.LogFormat("Received: {0}.",${event.data});
    ///         };
    ///
    ///         dataChennel.OnOpen = () => {
    ///             Debug.Log("DataChannel opened.");
    ///         };
    ///
    ///         dataChennel.OnClose = () => {
    ///             Debug.Log("DataChannel closed.");
    ///         };
    ///     ]]></code>
    /// </example>
    /// <seealso cref="RTCPeerConnection.CreateDataChannel(string, RTCDataChannelInit)"/>
    public class RTCDataChannel : RefCountedObject
    {
        private DelegateOnMessage onMessage;
        private DelegateOnOpen onOpen;
        private DelegateOnClose onClose;
        private DelegateOnError onError;

        /// <summary>
        /// Delegate to be called when a message has been received from the remote peer.
        /// </summary>
        /// <remarks>
        /// The WebRTC message event is sent to the onmessage event handler on an RTCDataChannel object when a message has been received from the remote peer.
        /// </remarks>
        public DelegateOnMessage OnMessage
        {
            get => onMessage;
            set => onMessage = value;
        }

        /// <summary>
        /// Delegate to be called when the data channel's messages is opened or reopened.
        /// </summary>
        /// <remarks>
        /// The WebRTC open event is sent to an RTCDataChannel object's onopen event handler when the underlying transport used to send and receive the data channel's messages is opened or reopened.
        /// This event is not cancelable and does not bubble.
        /// </remarks>
        public DelegateOnOpen OnOpen
        {
            get => onOpen;
            set => onOpen = value;
        }

        /// <summary>
        /// Delegate to be called when the data channel's messages is closed.
        /// </summary>
        /// <remarks>
        /// The close event is sent to the onclose event handler on an RTCDataChannel instance when the data transport for the data channel has closed.
        /// Before any further data can be transferred using RTCDataChannel, a new 'RTCDataChannel' instance must be created.
        /// This event is not cancelable and does not bubble.
        /// </remarks>
        public DelegateOnClose OnClose
        {
            get => onClose;
            set => onClose = value;
        }

        /// <summary>
        /// Delegate to be called when the errors occur.
        /// </summary>
        /// <remarks>
        /// A WebRTC error event is sent to an RTCDataChannel object's onerror event handler when an error occurs on the data channel.
        /// The RTCErrorEvent object provides details about the error that occurred; see that article for details.
        /// This event is not cancelable and does not bubble.
        /// </remarks>
        public DelegateOnError OnError
        {
            get => onError;
            set => onError = value;
        }

        /// <summary>
        /// Returns an ID number (between 0 and 65,534) which uniquely identifies the RTCDataChannel.
        /// </summary>
        /// <remarks>
        /// Returns an ID number (between 0 and 65,534) which uniquely identifies the RTCDataChannel. This ID is set at the time the data channel is created, either by the user agent (if RTCDataChannel.negotiated is false) or by the site or app script (if negotiated is true).
        /// Each RTCPeerConnection can therefore have up to a theoretical maximum of 65,534 data channels on it.
        /// </remarks>
        public int Id => NativeMethods.DataChannelGetID(GetSelfOrThrow());

        /// <summary>
        /// Returns a string containing a name describing the data channel which are not required to be unique.
        /// </summary>
        /// <remarks>
        ///
        /// </remarks>
        public string Label => NativeMethods.DataChannelGetLabel(GetSelfOrThrow()).AsAnsiStringWithFreeMem();

        /// <summary>
        /// Returns a string containing a name describing the data channel. These labels are not required to be unique.
        /// </summary>
        /// <remarks>
        /// Returns a string containing a name describing the data channel. These labels are not required to be unique.
        /// You may use the label as you wish; you could use it to identify all the channels that are being used for the same purpose, by giving them all the same name.
        /// Or you could give each channel a unique label for tracking purposes. It's entirely up to the design decisions made when building your site or app.
        /// </remarks>
        public string Protocol => NativeMethods.DataChannelGetProtocol(GetSelfOrThrow()).AsAnsiStringWithFreeMem();

        /// <summary>
        /// Returns the maximum number of times the browser should try to retransmit a message before giving up.
        /// </summary>
        /// <remarks>
        /// Returns the maximum number of times the browser should try to retransmit a message before giving up,
        /// as set when the data channel was created, or null, which indicates that there is no maximum.
        /// This can only be set when the RTCDataChannel is created by calling RTCPeerConnection.createDataChannel(), using the maxRetransmits field in the specified options.
        /// </remarks>
        public ushort MaxRetransmits => NativeMethods.DataChannelGetMaxRetransmits(GetSelfOrThrow());

        /// <summary>
        /// Returns the amount of time, in milliseconds, the browser is allowed to take to attempt to transmit a message, as set when the data channel was created, or null.
        /// </summary>
        /// <remarks>
        /// Returns the amount of time, in milliseconds, the browser is allowed to take to attempt to transmit a message, as set when the data channel was created, or null.
        /// This limits how long the browser can continue to attempt to transmit and retransmit the message before giving up.
        /// </remarks>
        public ushort MaxRetransmitTime => NativeMethods.DataChannelGetMaxRetransmitTime(GetSelfOrThrow());

        /// <summary>
        /// Indicates whether or not the data channel guarantees in-order delivery of messages.
        /// </summary>
        /// <remarks>
        /// indicates whether or not the data channel guarantees in-order delivery of messages; the default is true, which indicates that the data channel is indeed ordered.
        /// This is set when the RTCDataChannel is created, by setting the ordered property on the object passed as RTCPeerConnection.createDataChannel()'s options parameter.
        /// </remarks>
        public bool Ordered => NativeMethods.DataChannelGetOrdered(GetSelfOrThrow());

        /// <summary>
        /// Returns the number of bytes of data currently queued to be sent over the data channel.
        /// </summary>
        /// <remarks>
        ///
        /// </remarks>
        public ulong BufferedAmount => NativeMethods.DataChannelGetBufferedAmount(GetSelfOrThrow());

        /// <summary>
        /// Indicates whether the RTCDataChannel's connection is negotiated by the Web app or by the WebRTC layer.
        /// </summary>
        /// <remarks>
        ///
        /// </remarks>
        public bool Negotiated => NativeMethods.DataChannelGetNegotiated(GetSelfOrThrow());

        /// <summary>
        /// Returns an enum of the <c>RTCDataChannelState</c> which shows
        /// the state of the channel.
        /// </summary>
        /// <remarks>
        /// <see cref="Send(string)"/> method must be called when the state is <b>Open</b>.
        /// </remarks>
        /// <seealso cref="RTCDataChannelState"/>
        public RTCDataChannelState ReadyState => NativeMethods.DataChannelGetReadyState(GetSelfOrThrow());

        [AOT.MonoPInvokeCallback(typeof(DelegateNativeOnMessage))]
        static void DataChannelNativeOnMessage(IntPtr ptr, byte[] msg, int size)
        {
            WebRTC.Sync(ptr, () =>
            {
                if (WebRTC.Table[ptr] is RTCDataChannel channel)
                {
                    channel.onMessage?.Invoke(msg);
                }
            });
        }

        [AOT.MonoPInvokeCallback(typeof(DelegateNativeOnOpen))]
        static void DataChannelNativeOnOpen(IntPtr ptr)
        {
            WebRTC.Sync(ptr, () =>
            {
                if (WebRTC.Table[ptr] is RTCDataChannel channel)
                {
                    channel.onOpen?.Invoke();
                }
            });
        }

        [AOT.MonoPInvokeCallback(typeof(DelegateNativeOnClose))]
        static void DataChannelNativeOnClose(IntPtr ptr)
        {
            WebRTC.Sync(ptr, () =>
            {
                if (WebRTC.Table[ptr] is RTCDataChannel channel)
                {
                    channel.onClose?.Invoke();
                }
            });
        }

        [AOT.MonoPInvokeCallback(typeof(DelegateNativeOnError))]
        static void DataChannelNativeOnError(IntPtr ptr, RTCErrorType errorType, byte[] message, int size)
        {
            WebRTC.Sync(ptr, () =>
            {
                if (WebRTC.Table[ptr] is RTCDataChannel channel)
                {
                    channel.onError?.Invoke(new RTCError() { errorType = errorType, message = System.Text.Encoding.UTF8.GetString(message) });
                }
            });
        }


        internal RTCDataChannel(IntPtr ptr, RTCPeerConnection peerConnection)
            : base(ptr)
        {
            WebRTC.Table.Add(self, this);
            WebRTC.Context.DataChannelRegisterOnMessage(self, DataChannelNativeOnMessage);
            WebRTC.Context.DataChannelRegisterOnOpen(self, DataChannelNativeOnOpen);
            WebRTC.Context.DataChannelRegisterOnClose(self, DataChannelNativeOnClose);
            WebRTC.Context.DataChannelRegisterOnError(self, DataChannelNativeOnError);
        }

        /// <summary>
        ///
        /// </summary>
        ~RTCDataChannel()
        {
            this.Dispose();
        }

        /// <summary>
        /// Release all the resources RTCDataChannel instance has allocated.
        /// </summary>
        /// <remarks>
        ///
        /// </remarks>
        public override void Dispose()
        {
            if (this.disposed)
            {
                return;
            }
            if (self != IntPtr.Zero && !WebRTC.Context.IsNull)
            {
                Close();
                WebRTC.Context.DeleteDataChannel(self);
                WebRTC.Table.Remove(self);
            }
            base.Dispose();
        }

        /// <summary>
        /// Sends data across the data channel to the remote peer.
        /// </summary>
        /// <remarks>
        /// Sends data across the data channel to the remote peer.
        /// This can be done any time except during the initial process of creating the underlying transport channel.
        /// Data sent before connecting is buffered if possible (or an error occurs if it's not possible),
        /// and is also buffered if sent while the connection is closing or closed.
        /// </remarks>
        /// <exception cref="InvalidOperationException">
        /// The method throws <c>InvalidOperationException</c> when <see cref="ReadyState"/>
        ///  is not <b>Open</b>.
        /// </exception>
        /// <param name="msg"></param>
        /// <seealso cref="ReadyState"/>
        public void Send(string msg)
        {
            if (ReadyState != RTCDataChannelState.Open)
            {
                throw new InvalidOperationException("DataChannel is not open");
            }
            NativeMethods.DataChannelSend(GetSelfOrThrow(), msg);
        }

        /// <summary>
        /// Sends data across the data channel to the remote peer.
        /// </summary>
        /// <remarks>
        /// Sends data across the data channel to the remote peer.
        /// This can be done any time except during the initial process of creating the underlying transport channel.
        /// Data sent before connecting is buffered if possible (or an error occurs if it's not possible),
        /// and is also buffered if sent while the connection is closing or closed.
        /// </remarks>
        /// <exception cref="InvalidOperationException">
        /// The method throws <c>InvalidOperationException</c> when <see cref="ReadyState"/>
        ///  is not <b>Open</b>.
        /// </exception>
        /// <param name="msg"></param>
        /// <seealso cref="ReadyState"/>
        public void Send(byte[] msg)
        {
            if (ReadyState != RTCDataChannelState.Open)
            {
                throw new InvalidOperationException("DataChannel is not open");
            }
            NativeMethods.DataChannelSendBinary(GetSelfOrThrow(), msg, msg.Length);
        }

        /// <summary>
        /// Sends data across the data channel to the remote peer.
        /// </summary>
        /// <remarks>
        /// Sends data across the data channel to the remote peer.
        /// This can be done any time except during the initial process of creating the underlying transport channel.
        /// Data sent before connecting is buffered if possible (or an error occurs if it's not possible),
        /// and is also buffered if sent while the connection is closing or closed.
        /// </remarks>
        /// <exception cref="InvalidOperationException">
        /// The method throws <c>InvalidOperationException</c> when <see cref="ReadyState"/>
        ///  is not <b>Open</b>.
        /// </exception>
        /// <typeparam name="T"></typeparam>
        /// <param name="msg"></param>
        public unsafe void Send<T>(NativeArray<T> msg)
            where T : struct
        {
            if (ReadyState != RTCDataChannelState.Open)
            {
                throw new InvalidOperationException("DataChannel is not open");
            }
            if (!msg.IsCreated)
            {
                throw new ArgumentException("Message array has not been created.", nameof(msg));
            }
            NativeMethods.DataChannelSendPtr(GetSelfOrThrow(), new IntPtr(msg.GetUnsafeReadOnlyPtr()), msg.Length * UnsafeUtility.SizeOf<T>());
        }

        /// <summary>
        /// Sends data across the data channel to the remote peer.
        /// </summary>
        /// <remarks>
        /// Sends data across the data channel to the remote peer.
        /// This can be done any time except during the initial process of creating the underlying transport channel.
        /// Data sent before connecting is buffered if possible (or an error occurs if it's not possible),
        /// and is also buffered if sent while the connection is closing or closed.
        /// </remarks>
        /// <exception cref="InvalidOperationException">
        /// The method throws <c>InvalidOperationException</c> when <see cref="ReadyState"/>
        ///  is not <b>Open</b>.
        /// </exception>
        /// <typeparam name="T"></typeparam>
        /// <param name="msg"></param>
        public unsafe void Send<T>(NativeSlice<T> msg)
            where T : struct
        {
            if (ReadyState != RTCDataChannelState.Open)
            {
                throw new InvalidOperationException("DataChannel is not open");
            }
            NativeMethods.DataChannelSendPtr(GetSelfOrThrow(), new IntPtr(msg.GetUnsafeReadOnlyPtr()), msg.Length * UnsafeUtility.SizeOf<T>());
        }

#if UNITY_2020_1_OR_NEWER // ReadOnly support was introduced in 2020.1

        /// <summary>
        /// Sends data across the data channel to the remote peer.
        /// </summary>
        /// <remarks>
        /// Sends data across the data channel to the remote peer.
        /// This can be done any time except during the initial process of creating the underlying transport channel.
        /// Data sent before connecting is buffered if possible (or an error occurs if it's not possible),
        /// and is also buffered if sent while the connection is closing or closed.
        /// </remarks>
        /// <exception cref="InvalidOperationException">
        /// The method throws <c>InvalidOperationException</c> when <see cref="ReadyState"/>
        ///  is not <b>Open</b>.
        /// </exception>        /// <typeparam name="T"></typeparam>
        /// <param name="msg"></param>
        public unsafe void Send<T>(NativeArray<T>.ReadOnly msg)
            where T : struct
        {
            if (ReadyState != RTCDataChannelState.Open)
            {
                throw new InvalidOperationException("DataChannel is not open");
            }
            NativeMethods.DataChannelSendPtr(GetSelfOrThrow(), new IntPtr(msg.GetUnsafeReadOnlyPtr()), msg.Length * UnsafeUtility.SizeOf<T>());
        }
#endif

        /// <summary>
        /// Sends data across the data channel to the remote peer.
        /// </summary>
        /// <remarks>
        /// Sends data across the data channel to the remote peer.
        /// This can be done any time except during the initial process of creating the underlying transport channel.
        /// Data sent before connecting is buffered if possible (or an error occurs if it's not possible),
        /// and is also buffered if sent while the connection is closing or closed.
        /// </remarks>
        /// <exception cref="InvalidOperationException">
        /// The method throws <c>InvalidOperationException</c> when <see cref="ReadyState"/>
        ///  is not <b>Open</b>.
        /// </exception>
        /// <param name="msgPtr"></param>
        /// <param name="length"></param>
        public unsafe void Send(void* msgPtr, int length)
        {
            if (ReadyState != RTCDataChannelState.Open)
            {
                throw new InvalidOperationException("DataChannel is not open");
            }
            NativeMethods.DataChannelSendPtr(GetSelfOrThrow(), new IntPtr(msgPtr), length);
        }

        /// <summary>
        /// Sends data across the data channel to the remote peer.
        /// </summary>
        /// <remarks>
        /// Sends data across the data channel to the remote peer.
        /// This can be done any time except during the initial process of creating the underlying transport channel.
        /// Data sent before connecting is buffered if possible (or an error occurs if it's not possible),
        /// and is also buffered if sent while the connection is closing or closed.
        /// </remarks>
        /// <exception cref="InvalidOperationException">
        /// The method throws <c>InvalidOperationException</c> when <see cref="ReadyState"/>
        ///  is not <b>Open</b>.
        /// </exception>        /// <param name="msgPtr"></param>
        /// <param name="length"></param>
        public void Send(IntPtr msgPtr, int length)
        {
            if (ReadyState != RTCDataChannelState.Open)
            {
                throw new InvalidOperationException("DataChannel is not open");
            }
            if (msgPtr != IntPtr.Zero && length > 0)
            {
                NativeMethods.DataChannelSendPtr(GetSelfOrThrow(), msgPtr, length);
            }
        }

        /// <summary>
        /// Closes the RTCDataChannel. Either peer is permitted to call this method to initiate closure of the channel.
        /// </summary>
        /// <remarks>
        /// Closes the RTCDataChannel. Either peer is permitted to call this method to initiate closure of the channel.
        /// Closure of the data channel is not instantaneous. Most of the process of closing the connection is handled asynchronously;
        /// you can detect when the channel has finished closing by watching for a close event on the data channel.
        /// </remarks>
        public void Close()
        {
            NativeMethods.DataChannelClose(GetSelfOrThrow());
        }
    }
}
